import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/team_provider.dart';

class EditTeamScreen extends StatefulWidget {
  final String teamid;
  final String teamname;
  final String teamcode;
  final String status;

  const EditTeamScreen({
    Key? key,
    required this.teamid,
    required this.teamname,
    required this.teamcode,
    required this.status,
  }) : super(key: key);

  @override
  _EditTeamScreenState createState() => _EditTeamScreenState();
}

class _EditTeamScreenState extends State<EditTeamScreen> {
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _statusController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.teamname);
    _codeController = TextEditingController(text: widget.teamcode);
    _statusController = TextEditingController(text: widget.status);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _updateTeam() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Team name cannot be empty')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final teamProvider = Provider.of<TeamProvider>(context, listen: false);
      await teamProvider.updateTeam(
        teamid: widget.teamid,
        teamname: _nameController.text,
        teamcode: _codeController.text,
        status: _statusController.text,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update team: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Team'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Team Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Team Code',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _statusController,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateTeam,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Update Team'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
