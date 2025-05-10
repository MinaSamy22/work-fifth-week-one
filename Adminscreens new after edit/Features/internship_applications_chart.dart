import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class InternshipApplicationsChart extends StatefulWidget {
  const InternshipApplicationsChart({Key? key}) : super(key: key);

  @override
  State<InternshipApplicationsChart> createState() => _InternshipApplicationsChartState();
}

class _InternshipApplicationsChartState extends State<InternshipApplicationsChart> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<InternshipData> _topInternships = [];
  List<InternshipData> _zeroApplicantInternships = [];
  String? _errorMessage;
  int _displayLimit = 5;

  @override
  void initState() {
    super.initState();
    _fetchInternshipApplicationsData();
  }

  Future<void> _fetchInternshipApplicationsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final internshipSnapshot = await _firestore.collection('interns').get();
      final List<InternshipData> allInternships = [];

      for (var internDoc in internshipSnapshot.docs) {
        try {
          final internshipId = internDoc.id;
          final title = internDoc.data()['title'] ?? 'Untitled Internship';

          final applicantsSnapshot = await _firestore
              .collection('Student_Applicant')
              .where('internshipId', isEqualTo: internshipId)
              .get();

          allInternships.add(InternshipData(
            internshipId: internshipId,
            internshipTitle: _truncateTitle(title),
            applicantsCount: applicantsSnapshot.docs.length,
          ));
        } catch (e) {
          debugPrint('Error processing internship ${internDoc.id}: $e');
          _errorMessage = 'Partial data loaded - some items may be missing';
        }
      }

      allInternships.sort((a, b) => b.applicantsCount.compareTo(a.applicantsCount));

      setState(() {
        _topInternships = allInternships.where((i) => i.applicantsCount > 0).toList();
        _zeroApplicantInternships = allInternships.where((i) => i.applicantsCount == 0).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching internship data: $e');
      setState(() {
        _errorMessage = 'Failed to load internship data';
        _isLoading = false;
      });
    }
  }

  String _truncateTitle(String title) {
    return title.length > 15 ? '${title.substring(0, 15)}...' : title;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title always visible
          Text(
            'Internship Applications',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2252A1),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            _buildErrorWidget(_errorMessage!)
          else if (_topInternships.isEmpty && _zeroApplicantInternships.isEmpty)
              _buildErrorWidget('No internship data available')
            else
              Column(
                children: [
                  // Only show this dropdown after loading
                  if (!_isLoading && _topInternships.length > 5)
                    Align(
                      alignment: Alignment.centerRight,
                      child: DropdownButton<int>(
                        value: _displayLimit,
                        items: [5, 10, 15, 20].map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text('Top $value'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _displayLimit = value!;
                          });
                        },
                      ),
                    ),

                  // Only show chart after loading
                  if (!_isLoading && _topInternships.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      height: 250,
                      padding: const EdgeInsets.only(right: 16.0, top: 16, bottom: 12),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (_findMaxApplicants(_topInternships) * 1.2).roundToDouble(),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final internship = _topInternships[groupIndex];
                                return BarTooltipItem(
                                  '${internship.internshipTitle}\n',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: '${rod.toY.round()} applicant${rod.toY.round() == 1 ? '' : 's'}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value < 0 || value >= _topInternships.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Transform.rotate(
                                      angle: -0.3,
                                      child: Text(
                                        _topInternships[value.toInt()].internshipTitle,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                reservedSize: 42,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  if (value == 0) return const SizedBox.shrink();
                                  return Text(
                                    value.toInt().toString(),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            show: true,
                            horizontalInterval: 1,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey[300],
                                strokeWidth: 1,
                                dashArray: [5],
                              );
                            },
                          ),
                          barGroups: List.generate(
                            _topInternships.take(_displayLimit).length,
                                (index) => BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: _topInternships[index].applicantsCount.toDouble(),
                                  color: _getBarColor(index),
                                  width: 20,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(6),
                                    topRight: Radius.circular(6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Top ${_displayLimit} Internships by Applicants ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],

                  // Only show zero applicant section after loading
                  if (!_isLoading && _zeroApplicantInternships.isNotEmpty) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: Text(
                        'Internships With No Applicants (${_zeroApplicantInternships.length})',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _zeroApplicantInternships
                          .take(10)
                          .map((internship) => Chip(
                        label: Text(internship.internshipTitle),
                        backgroundColor: Colors.grey[200],
                        visualDensity: VisualDensity.compact,
                      ))
                          .toList(),
                    ),
                    if (_zeroApplicantInternships.length > 10)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '+ ${_zeroApplicantInternships.length - 10} more',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          message,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  double _findMaxApplicants(List<InternshipData> data) {
    if (data.isEmpty) return 10;
    return data
        .map((data) => data.applicantsCount.toDouble())
        .reduce((a, b) => a > b ? a : b);
  }

  Color _getBarColor(int index) {
    List<Color> colors = [
      const Color(0xFF2252A1), // Primary blue
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFFA000), // Amber
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFF44336), // Red
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFF8BC34A), // Light Green
      const Color(0xFF795548), // Brown
      const Color(0xFF607D8B), // Blue Grey
    ];
    return colors[index % colors.length];
  }
}

class InternshipData {
  final String internshipId;
  final String internshipTitle;
  final int applicantsCount;

  InternshipData({
    required this.internshipId,
    required this.internshipTitle,
    required this.applicantsCount,
  });
}