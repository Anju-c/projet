import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../../models/team_model.dart';
import '../../../providers/task_provider.dart';
import '../../../models/task_model.dart';

class SprintProgressChart extends StatefulWidget {
  final List<TeamModel> teams;

  const SprintProgressChart({super.key, required this.teams});

  @override
  State<SprintProgressChart> createState() => _SprintProgressChartState();
}

class _SprintProgressChartState extends State<SprintProgressChart> {
  final Map<String, double> _teamProgress = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTeamProgress();
  }

  Future<void> _loadTeamProgress() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    try {
      for (final team in widget.teams) {
        final tasks = taskProvider.tasks;
        final teamTasks = tasks.where((task) => task.teamId == team.teamid).toList();
        
        final totalTasks = teamTasks.length;
        final completedTasks = teamTasks.where((task) => task.status == TaskStatus.done).length;
        final progressPercentage = totalTasks == 0 ? 0.0 : (completedTasks / totalTasks) * 100;
        
        if (!mounted) return;
        setState(() {
          _teamProgress[team.teamid] = progressPercentage;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Error loading sprint progress: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTeamProgress,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_teamProgress.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              'No team progress data available',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const Text(
          'Sprint Progress by Team',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: PieChart(
                  PieChartData(
                    sections: _buildPieChartSections(),
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildTeamProgressIndicators(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.pink,
    ];

    return List.generate(_teamProgress.length, (index) {
      final teamId = _teamProgress.keys.elementAt(index);
      final progress = _teamProgress[teamId]!;
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: progress,
        title: '${progress.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  List<Widget> _buildTeamProgressIndicators() {
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.pink,
    ];

    return List.generate(_teamProgress.length, (index) {
      final teamId = _teamProgress.keys.elementAt(index);
      final team = widget.teams.firstWhere((t) => t.teamid == teamId);
      final progress = _teamProgress[teamId]!;
      final color = colors[index % colors.length];

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    team.teamname,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearPercentIndicator(
              lineHeight: 8.0,
              percent: progress / 100,
              backgroundColor: Colors.grey.shade200,
              progressColor: color,
              barRadius: const Radius.circular(4),
              padding: const EdgeInsets.only(right: 16),
            ),
          ],
        ),
      );
    });
  }
}
