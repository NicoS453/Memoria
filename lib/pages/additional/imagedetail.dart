import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageDetail extends StatefulWidget {
  final String imageUrl;
  final String username;
  final String caption;
  final String uuid;
  final String id;

  const ImageDetail({
    super.key,
    required this.imageUrl,
    required this.username,
    required this.caption,
    required this.uuid,
    required this.id,
  });

  @override
  _ImageDetailState createState() => _ImageDetailState();
}

class _ImageDetailState extends State<ImageDetail> {
  bool isLiked = false;
  int likeCount = 0;
  List<Map<String, dynamic>> comments = [];
  bool hasCommented = false;
  final TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchLikeStatus();
    fetchComments();
  }

  void onSubmitComment(String postId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      Fluttertoast.showToast(msg: "Anda harus login untuk berkomentar.");
      return;
    }

    if (hasCommented) {
      Fluttertoast.showToast(
          msg: "Anda sudah pernah memberikan komentar di postingan ini.");
      return;
    }

    final commentText = commentController.text.trim();
    if (commentText.isEmpty) {
      Fluttertoast.showToast(msg: "Komentar tidak boleh kosong.");
      return;
    }

    await addComment(postId, commentText);
    commentController.clear();
  }

  Future<void> fetchComments() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    try {
      final response = await supabase
          .from('comments')
          .select('comment, created_at, user_id, profile(username)')
          .eq('post_id', widget.id)
          .order('posted_at', ascending: false);

      setState(() {
        comments = List<Map<String, dynamic>>.from(response);
        hasCommented = userId != null &&
            response.any((comment) => comment['user_id'] == userId);
      });
    } catch (e) {
      debugPrint("Error fetching comments: $e");
    }
  }

  Future<void> addComment(String postId, String commentText) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) {
        Fluttertoast.showToast(msg: "Anda harus login untuk berkomentar.");
        return;
      }

      await Supabase.instance.client.from('comments').insert({
        'post_id': postId,
        'user_id': userId,
        'comment': commentText,
        'created_at': DateTime.now().toIso8601String(),
      });

      Fluttertoast.showToast(msg: "Komentar berhasil ditambahkan!");
      fetchComments();
    } catch (error) {
      debugPrint('Error adding comment: $error');
      Fluttertoast.showToast(msg: "Gagal menambahkan komentar.");
    }
  }

  Future<void> fetchLikeStatus() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('likes')
          .select()
          .eq('image_id', widget.id)
          .eq('user_id', user.id)
          .maybeSingle();

      final countResponse =
          await supabase.from('likes').select().eq('image_id', widget.id);

      setState(() {
        isLiked = response != null;
        likeCount = countResponse.length;
      });
    } catch (e) {
      debugPrint("Error fetching like status: $e");
    }
  }

  Future<void> toggleLike() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      if (isLiked) {
        await supabase
            .from('likes')
            .delete()
            .eq('image_id', widget.id)
            .eq('user_id', user.id);
      } else {
        await supabase.from('likes').insert({
          'image_id': widget.id,
          'user_id': user.id,
        });
      }
      fetchLikeStatus();
    } catch (e) {
      debugPrint("Error toggling like: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Image'),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: const EdgeInsets.only(right: 16,left: 16,bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: MediaQuery.of(context).size.height / 2.1,
                width: double.infinity,
                color: Colors.grey[200],
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.network(
                    widget.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text(
                    'Diupload oleh:',
                    style: TextStyle(fontSize: 10),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    widget.username,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 24),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                widget.caption.isNotEmpty ? widget.caption : 'No Caption',
                style: const TextStyle(fontSize: 20),
                maxLines: null,
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: toggleLike,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        Text(
                          '$likeCount Likes',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: MediaQuery.of(context).size.height / 6,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: comments.length,
                  separatorBuilder: (context, index) => const Divider(), // Tambahkan garis pemisah
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final username = comment['profile']['username'];

                    return ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(comment['comment']),
                        ],
                      ),
                      subtitle: Text(comment['created_at'].toString()),
                    );
                  },
                ),
              ),
              if (hasCommented)
                Padding(
                  padding: const EdgeInsets.only(top: 3, bottom: 5),
                  child: Text(
                    "Anda sudah pernah memberikan komentar di postingan ini.",
                    style: TextStyle(fontWeight: FontWeight.bold,fontSize: 12),
                  ),
                ),
              TextField(
                controller: commentController,
                enabled: !hasCommented, // Matikan input jika sudah berkomentar
                decoration: InputDecoration(
                  hintText: 'Tambahkan komentar...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed:
                        hasCommented ? null : () => onSubmitComment(widget.id),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
