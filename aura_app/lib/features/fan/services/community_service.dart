import '../../../core/supabase_config.dart';
import '../models/community_post_model.dart';
import '../models/community_comment_model.dart';
import '../../auth/models/user_model.dart';

/// 커뮤니티 서비스
/// 
/// WP-2.5: 팬 커뮤니티 (게시글/댓글)
/// 
/// Supabase의 communities 및 community_comments 테이블에서 
/// 게시글과 댓글 정보를 조회/생성/수정/삭제하는 서비스입니다.
class CommunityService {
  /// 게시글 생성
  /// 
  /// [title]: 게시글 제목
  /// [content]: 게시글 내용
  /// 
  /// Returns: 생성된 게시글
  /// Throws: 게시글 생성 실패 시
  static Future<CommunityPostModel> createPost({
    required String title,
    required String content,
  }) async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final postData = <String, dynamic>{
        'user_id': currentUser.id,
        'title': title.trim(),
        'content': content.trim(),
        'view_count': 0,
      };

      final response = await client
          .from('communities')
          .insert(postData)
          .select()
          .single();

      final post = CommunityPostModel.fromJson(response);
      print('✅ 게시글 생성 성공: ${post.id}');
      return post;
    } catch (e) {
      print('❌ 게시글 생성 실패: $e');
      rethrow;
    }
  }

  /// 게시글 목록 조회
  /// 
  /// [limit]: 조회할 게시글 수 (기본값: 20)
  /// [offset]: 시작 위치 (기본값: 0)
  /// [sortBy]: 정렬 기준 ('created_at' 또는 'comment_count', 기본값: 'created_at')
  /// [orderBy]: 정렬 방향 ('asc' 또는 'desc', 기본값: 'desc')
  /// [searchQuery]: 검색어 (제목/내용 검색, 기본값: null)
  /// 
  /// Returns: 게시글 목록 (댓글 수 포함)
  /// Throws: 게시글 조회 실패 시
  static Future<List<CommunityPostModel>> getPosts({
    int limit = 20,
    int offset = 0,
    String sortBy = 'created_at',
    String orderBy = 'desc',
    String? searchQuery,
  }) async {
    try {
      final client = SupabaseConfig.client;

      // 검색어가 있으면 제목 또는 내용에서 검색
      // Supabase의 or() 필터가 불안정할 수 있으므로, 클라이언트 사이드에서 필터링
      dynamic queryBuilder = client.from('communities').select();
      
      // 정렬
      if (sortBy == 'comment_count') {
        // 댓글 수 기준 정렬은 클라이언트 사이드에서 처리
        // (Supabase에서 직접 집계하기 어려움)
        queryBuilder = queryBuilder.order('created_at', ascending: orderBy == 'asc');
      } else {
        queryBuilder = queryBuilder.order(sortBy, ascending: orderBy == 'asc');
      }

      // 검색어가 없으면 더 많은 데이터를 가져와서 클라이언트 사이드에서 필터링
      // (검색어가 있으면 더 넓은 범위에서 검색)
      final fetchLimit = searchQuery != null && searchQuery.trim().isNotEmpty ? limit * 3 : limit;
      queryBuilder = queryBuilder.range(0, offset + fetchLimit - 1);

      final response = await queryBuilder;

      final postsData = response as List;

      // 각 게시글의 댓글 수 조회 및 검색 필터링
      final posts = <CommunityPostModel>[];
      final trimmedQuery = searchQuery?.trim().toLowerCase() ?? '';
      
      for (final json in postsData) {
        final data = json as Map<String, dynamic>;
        final postId = data['id'] as String;
        final title = (data['title'] as String? ?? '').toLowerCase();
        final content = (data['content'] as String? ?? '').toLowerCase();

        // 검색어 필터링 (클라이언트 사이드)
        if (trimmedQuery.isNotEmpty) {
          if (!title.contains(trimmedQuery) && !content.contains(trimmedQuery)) {
            continue; // 검색어가 제목이나 내용에 없으면 건너뛰기
          }
        }

        // 댓글 수 조회
        int commentCount = 0;
        try {
          final commentsResponse = await client
              .from('community_comments')
              .select('id')
              .eq('community_id', postId);

          commentCount = (commentsResponse as List).length;
        } catch (e) {
          print('⚠️ 댓글 수 조회 실패: $e (계속 진행)');
        }

        posts.add(CommunityPostModel.fromJson(data, commentCount: commentCount));
      }

      // 댓글 수 기준 정렬이면 클라이언트 사이드에서 정렬
      if (sortBy == 'comment_count') {
        posts.sort((a, b) {
          final comparison = a.commentCount.compareTo(b.commentCount);
          return orderBy == 'desc' ? -comparison : comparison;
        });
      }

      // 페이지네이션 적용 (검색 필터링 후)
      final startIndex = offset;
      final endIndex = offset + limit;
      final paginatedPosts = posts.length > startIndex
          ? posts.sublist(startIndex, endIndex > posts.length ? posts.length : endIndex)
          : <CommunityPostModel>[];

      print('✅ 게시글 목록 조회 성공: ${paginatedPosts.length}개 (전체: ${posts.length}개)');
      return paginatedPosts;
    } catch (e) {
      print('❌ 게시글 목록 조회 실패: $e');
      rethrow;
    }
  }

  /// 게시글 상세 조회
  /// 
  /// [postId]: 게시글 ID
  /// 
  /// Returns: 게시글 정보 (없으면 null, 댓글 수 포함)
  /// Throws: 게시글 조회 실패 시
  static Future<CommunityPostModel?> getPostById(String postId) async {
    try {
      final client = SupabaseConfig.client;

      final response = await client
          .from('communities')
          .select()
          .eq('id', postId)
          .maybeSingle();

      if (response != null) {
        // 댓글 수 조회
        int commentCount = 0;
        try {
          final commentsResponse = await client
              .from('community_comments')
              .select('id')
              .eq('community_id', postId);

          commentCount = (commentsResponse as List).length;
        } catch (e) {
          print('⚠️ 댓글 수 조회 실패: $e (계속 진행)');
        }

        // 조회수 증가
        try {
          await client
              .from('communities')
              .update({'view_count': (response['view_count'] as int? ?? 0) + 1})
              .eq('id', postId);
        } catch (e) {
          print('⚠️ 조회수 증가 실패: $e (계속 진행)');
        }

        final post = CommunityPostModel.fromJson(response, commentCount: commentCount);
        print('✅ 게시글 조회 성공: $postId');
        return post;
      }

      return null;
    } catch (e) {
      print('❌ 게시글 조회 실패: $e');
      rethrow;
    }
  }

  /// 게시글 수정
  /// 
  /// [postId]: 게시글 ID
  /// [title]: 수정할 제목
  /// [content]: 수정할 내용
  /// 
  /// Returns: 수정된 게시글
  /// Throws: 게시글 수정 실패 시
  static Future<CommunityPostModel> updatePost({
    required String postId,
    required String title,
    required String content,
  }) async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final updateData = <String, dynamic>{
        'title': title.trim(),
        'content': content.trim(),
      };

      final response = await client
          .from('communities')
          .update(updateData)
          .eq('id', postId)
          .eq('user_id', currentUser.id) // 작성자만 수정 가능
          .select()
          .single();

      final post = CommunityPostModel.fromJson(response);
      print('✅ 게시글 수정 성공: $postId');
      return post;
    } catch (e) {
      print('❌ 게시글 수정 실패: $e');
      rethrow;
    }
  }

  /// 게시글 삭제
  /// 
  /// [postId]: 게시글 ID
  /// 
  /// Throws: 게시글 삭제 실패 시
  static Future<void> deletePost(String postId) async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      await client
          .from('communities')
          .delete()
          .eq('id', postId)
          .eq('user_id', currentUser.id); // 작성자만 삭제 가능

      print('✅ 게시글 삭제 성공: $postId');
    } catch (e) {
      print('❌ 게시글 삭제 실패: $e');
      rethrow;
    }
  }

  /// 게시글 작성자 정보 조회
  /// 
  /// [userId]: 사용자 ID
  /// 
  /// Returns: 사용자 정보 (없으면 null)
  static Future<UserModel?> getPostAuthor(String userId) async {
    try {
      final client = SupabaseConfig.client;

      final response = await client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        return UserModel.fromJson(response);
      }

      return null;
    } catch (e) {
      print('⚠️ 게시글 작성자 조회 실패: $e');
      return null;
    }
  }

  /// 댓글 생성
  /// 
  /// [communityId]: 게시글 ID
  /// [content]: 댓글 내용
  /// 
  /// Returns: 생성된 댓글
  /// Throws: 댓글 생성 실패 시
  static Future<CommunityCommentModel> createComment({
    required String communityId,
    required String content,
  }) async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final commentData = <String, dynamic>{
        'community_id': communityId,
        'user_id': currentUser.id,
        'content': content.trim(),
      };

      final response = await client
          .from('community_comments')
          .insert(commentData)
          .select()
          .single();

      final comment = CommunityCommentModel.fromJson(response);
      print('✅ 댓글 생성 성공: ${comment.id}');
      return comment;
    } catch (e) {
      print('❌ 댓글 생성 실패: $e');
      rethrow;
    }
  }

  /// 댓글 목록 조회
  /// 
  /// [communityId]: 게시글 ID
  /// 
  /// Returns: 댓글 목록 (최신순)
  /// Throws: 댓글 조회 실패 시
  static Future<List<CommunityCommentModel>> getComments(String communityId) async {
    try {
      final client = SupabaseConfig.client;

      final response = await client
          .from('community_comments')
          .select()
          .eq('community_id', communityId)
          .order('created_at', ascending: true); // 최신순

      final commentsData = response as List;

      final comments = commentsData
          .map((json) => CommunityCommentModel.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ 댓글 목록 조회 성공: ${comments.length}개');
      return comments;
    } catch (e) {
      print('❌ 댓글 목록 조회 실패: $e');
      rethrow;
    }
  }

  /// 댓글 삭제
  /// 
  /// [commentId]: 댓글 ID
  /// 
  /// Throws: 댓글 삭제 실패 시
  static Future<void> deleteComment(String commentId) async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      await client
          .from('community_comments')
          .delete()
          .eq('id', commentId)
          .eq('user_id', currentUser.id); // 작성자만 삭제 가능

      print('✅ 댓글 삭제 성공: $commentId');
    } catch (e) {
      print('❌ 댓글 삭제 실패: $e');
      rethrow;
    }
  }

  /// 댓글 작성자 정보 조회
  /// 
  /// [userId]: 사용자 ID
  /// 
  /// Returns: 사용자 정보 (없으면 null)
  static Future<UserModel?> getCommentAuthor(String userId) async {
    try {
      final client = SupabaseConfig.client;

      final response = await client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        return UserModel.fromJson(response);
      }

      return null;
    } catch (e) {
      print('⚠️ 댓글 작성자 조회 실패: $e');
      return null;
    }
  }

  /// 내가 작성한 게시글 목록 조회
  /// 
  /// [limit]: 조회할 게시글 수 (기본값: 20)
  /// [offset]: 시작 위치 (기본값: 0)
  /// 
  /// Returns: 내가 작성한 게시글 목록
  /// Throws: 게시글 조회 실패 시
  static Future<List<CommunityPostModel>> getMyPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 현재 사용자가 작성한 게시글만 조회
      var query = client
          .from('communities')
          .select()
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final response = await query;

      final postsData = response as List;

      // 각 게시글의 댓글 수 조회
      final posts = <CommunityPostModel>[];
      
      for (final json in postsData) {
        final data = json as Map<String, dynamic>;
        final postId = data['id'] as String;

        // 댓글 수 조회
        int commentCount = 0;
        try {
          final commentsResponse = await client
              .from('community_comments')
              .select('id')
              .eq('community_id', postId);

          commentCount = (commentsResponse as List).length;
        } catch (e) {
          print('⚠️ 댓글 수 조회 실패: $e (계속 진행)');
        }

        posts.add(CommunityPostModel.fromJson(data, commentCount: commentCount));
      }

      print('✅ 내 게시글 목록 조회 성공: ${posts.length}개');
      return posts;
    } catch (e) {
      print('❌ 내 게시글 목록 조회 실패: $e');
      rethrow;
    }
  }
}

