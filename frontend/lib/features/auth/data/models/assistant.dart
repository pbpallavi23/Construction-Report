class Assistant {
  const Assistant({
    required this.assistantId,
    required this.fullName,
    required this.email,
    this.role = 'Site Engineer',
    this.phone,
    this.avatarUrl,
  });

  final String assistantId;
  final String fullName;
  final String email;
  final String role;
  final String? phone;
  final String? avatarUrl;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'B';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  factory Assistant.fromJson(Map<String, dynamic> json) => Assistant(
        assistantId: json['assistant_id'] as String,
        fullName: json['full_name'] as String,
        email: json['email'] as String,
        role: (json['role'] as String?) ?? 'Site Engineer',
        phone: json['phone'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'assistant_id': assistantId,
        'full_name': fullName,
        'email': email,
        'role': role,
        'phone': phone,
        'avatar_url': avatarUrl,
      };

  Assistant copyWith({String? fullName, String? phone, String? avatarUrl}) =>
      Assistant(
        assistantId: assistantId,
        fullName: fullName ?? this.fullName,
        email: email,
        role: role,
        phone: phone ?? this.phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );
}
