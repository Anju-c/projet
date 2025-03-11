import 'package:flutter/material.dart';
import '../../../models/user_model.dart';

class TeamMemberList extends StatelessWidget {
  final List<UserModel> members;
  final bool isTeacher;

  const TeamMemberList({
    super.key,
    required this.members,
    required this.isTeacher,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No team members yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // Separate teachers and students
    final teachers = members.where((member) => member.isTeacher).toList();
    final students = members.where((member) => !member.isTeacher).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (teachers.isNotEmpty) ...[
          const Text(
            'Guides',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 8),
          ...teachers.map((teacher) => _buildMemberTile(teacher, true)),
          const SizedBox(height: 24),
        ],
        if (students.isNotEmpty) ...[
          const Text(
            'Students',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 8),
          ...students.map((student) => _buildMemberTile(student, false)),
        ],
      ],
    );
  }

  Widget _buildMemberTile(UserModel member, bool isTeacher) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isTeacher ? Colors.blue.shade100 : Colors.deepPurple.shade100,
          child: Text(
            member.name.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: isTeacher ? Colors.blue.shade800 : Colors.deepPurple.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          member.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(member.email),
        trailing: Chip(
          label: Text(
            isTeacher ? 'Guide' : 'Student',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          backgroundColor: isTeacher ? Colors.blue.shade700 : Colors.deepPurple,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }
}