import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserImageDetail extends StatefulWidget {
  final String imageUrl;
  final String username;
  final String caption;
  final String uuid;
  final String id;

  const UserImageDetail({
    super.key,
    required this.imageUrl,
    required this.username,
    required this.caption,
    required this.uuid,
    required this.id,
  });

  @override
  _UserImageDetailState createState() => _UserImageDetailState();
}

class _UserImageDetailState extends State<UserImageDetail> {
  bool isLiked = false;
  int likeCount = 0;
  bool isFavorite = false;
  List<Map<String, dynamic>> comments = [];
  bool hasCommented = false;
  final TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchLikeStatus();
    fetchComments();
    checkFavoriteStatus();
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
          .order('created_at', ascending: false);

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
          .select('image_id,user_id')
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
  Future<void> _deleteImage() async {
    try {
      final supabase = Supabase.instance.client;

      // Hapus gambar dari tabel Supabase
      await supabase.from('image').delete().eq('id', widget.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gambar berhasil dihapus')),
      );

      // Kembali ke halaman profil setelah menghapus
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Gagal menghapus gambar: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus gambar: $e')),
      );
    }
  }
  void _showImageOptions(BuildContext context) {
    if (isFavorite == null) {
      // Handle jika isFavorite belum ditentukan
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Hapus Gambar'),
              onTap: () {
                Navigator.pop(context);
                _deleteImage();
              },
            ),
            ListTile(
              leading: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? Colors.yellow : null,
              ),
              title: Text(
                isFavorite ? 'Hapus dari Favorite' : 'Tambahkan ke Favorite',
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleFavorite();
              },
            ),
          ],
        );
      },
    );
  }
  Future<void> checkFavoriteStatus() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('favorite')
          .select('*')
          .eq('user_id', userId)
          .eq('image_id', widget.id)
          .maybeSingle();
      setState(() {
        isFavorite = response != null;
      });
    } catch (e) {
      debugPrint("Error checking favorite status: $e");
    }
  }

  Future<void> _toggleFavorite() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      if (isFavorite) {
        await Supabase.instance.client
            .from('favorite')
            .delete()
            .eq('user_id', userId)
            .eq('image_id', widget.id);
      } else {
        await Supabase.instance.client.from('favorite').insert({
          'user_id': userId,
          'image_id': widget.id,
        });
      }
      checkFavoriteStatus();
    } catch (e) {
      debugPrint("Error toggling favorite: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Your memories'),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Pisahkan antara username dan ikon
                children: [
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
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      _showImageOptions(context,);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.caption.isNotEmpty ? widget.caption : 'No Caption',
                      style: const TextStyle(fontSize: 25),
                      maxLines: null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
              const SizedBox(height: 5),
              SizedBox(
                height: MediaQuery.of(context).size.height / 4,
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
                          const SizedBox(height: 4),
                          Text(comment['comment']),
                        ],
                      ),
                      subtitle: Text(comment['created_at'].toString()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
