import 'package:flutter/material.dart';
import '../../../models/team_model.dart';

class TeamCard extends StatelessWidget {
  final TeamModel team;
  final VoidCallback onTap;

  const TeamCard({
    super.key,
    required this.team,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.deepPurple.shade100,
                    child: Text(
                      team.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Colors.deepPurple.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Team Code: ${team.code}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      team.isTeacher ? 'Guide' : 'Member',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: team.isTeacher
                        ? Colors.blue.shade700
                        : Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}