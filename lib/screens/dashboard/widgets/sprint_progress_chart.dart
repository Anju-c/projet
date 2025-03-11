import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../models/team_model.dart';
import '../../../providers/team_provider.dart';
import 'package:provider/provider.dart';

class SprintProgressChart extends StatefulWidget {
  final List<TeamModel> teams;

  const SprintProgressChart({
    super.key,
    required this.teams,
  });

  @override
  State<SprintProgressChart> createState() => _SprintProgressChartState();
}

class _SprintProgressChartState extends State<SprintProgressChart> {
  final Map<String, Map<String, dynamic>> _teamProgress = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeamProgress();
  }

  Future<void> _loadTeamProgress() async {
    setState(() {
      _isLoading = true;
    });

    final teamProvider = Provider.of<TeamProvider>(context, listen: false);

    for (final team in widget.teams) {
      final progress = await teamProvider.getSprintProgress(team.id);
      _teamProgress[team.id] = progress;
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_teamProgress.isEmpty) {
      return const Center(
        child: Text('No team progress data available'),
      );
    }

    return Column(
      children: [
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

    return List.generate(
      _teamProgress.length,
      (index) {
        final teamId = _teamProgress.keys.elementAt(index);
        final team = widget.teams.firstWhere((t) => t.id == teamId);
        final progress = _teamProgress[teamId]!;
        final percentage = progress['progress_percentage'] as double;
        
        return PieChartSectionData(
          color: colors[index % colors.length],
          value: percentage,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      },
    );
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

    return List.generate(
      _teamProgress.length,
      (index) {
        final teamId = _teamProgress.keys.elementAt(index);
        final team = widget.teams.firstWhere((t) => t.id == teamId);
        final progress = _teamProgress[teamId]!;
        final percentage = progress['progress_percentage'] as double;
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
                      team.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearPercentIndicator(
                lineHeight: 8.0,
                percent: percentage / 100,
                backgroundColor: Colors.grey.shade200,
                progressColor: color,
                barRadius: const Radius.circular(4),
                padding: const EdgeInsets.only(right: 16),
              ),
            ],
          ),
        );
      },
    );
  }
}