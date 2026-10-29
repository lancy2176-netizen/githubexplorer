class GitHubUser {
  const GitHubUser({
    required this.login,
    required this.avatarUrl,
    required this.url,
    this.id = 0,
    this.name,
    this.bio,
    this.location,
    this.company,
    this.blog,
    this.publicRepos = 0,
    this.followers = 0,
    this.following = 0,
    this.isDetailed = false,
  });
  final int id;
  final String login;
  final String avatarUrl;
  final String url;
  final String? name, bio, location, company, blog;
  final int publicRepos, followers, following;
  final bool isDetailed;

  factory GitHubUser.fromJson(Map<String, dynamic> json) => GitHubUser(
    id: json['id'] as int? ?? 0,
    login: json['login'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String? ?? '',
    url: json['html_url'] as String? ?? 'https://github.com/${json['login']}',
    name: json['name'] as String?,
    bio: json['bio'] as String?,
    location: json['location'] as String?,
    company: json['company'] as String?,
    blog: json['blog'] as String?,
    publicRepos: json['public_repos'] as int? ?? 0,
    followers: json['followers'] as int? ?? 0,
    following: json['following'] as int? ?? 0,
    isDetailed:
        json['is_detailed'] as bool? ?? json.containsKey('public_repos'),
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'login': login,
    'avatar_url': avatarUrl,
    'html_url': url,
    'name': name,
    'bio': bio,
    'location': location,
    'company': company,
    'blog': blog,
    'public_repos': publicRepos,
    'followers': followers,
    'following': following,
    'is_detailed': isDetailed,
  };
}
