import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/study_provider.dart';
import '../models/question.dart';
import 'question_detail_page.dart';
import 'statistics_page.dart';
import 'category_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TsingR 刷题'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree),
            tooltip: '分类浏览',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoryPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: '筛选',
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _currentIndex == 0 ? _buildQuestionsList() : const StatisticsPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: '题库',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '统计',
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsList() {
    return Consumer<StudyProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final questions = provider.filteredQuestions;

        return Column(
          children: [
            // 搜索框
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索题目...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            provider.setSearchKeyword('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) {
                  provider.setSearchKeyword(value);
                },
              ),
            ),

            // 统计信息
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: _buildStatChip('总题数', provider.totalQuestions)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatChip('已学', provider.studiedQuestions)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatChip('显示', questions.length)),
                ],
              ),
            ),

            // 题目列表
            Expanded(
              child: questions.isEmpty
                  ? const Center(child: Text('没有找到题目'))
                  : ListView.builder(
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        final question = questions[index];
                        return _buildQuestionCard(question);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatChip(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    return Consumer<StudyProvider>(
      builder: (context, provider, child) {
        final record = provider.getRecord(question.id);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuestionDetailPage(question: question),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 题目标题和热度
                  Row(
                    children: [
                      // 热度标签
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getPopularityColor(question.popularity),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '🔥 ${question.popularity}校',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 已学习次数
                      if (record.studyCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '✓ ${record.studyCount}次',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const Spacer(),
                      // 收藏按钮
                      IconButton(
                        icon: Icon(
                          record.isFavorite
                              ? Icons.star
                              : Icons.star_border,
                          color: record.isFavorite ? Colors.amber : null,
                        ),
                        onPressed: () {
                          provider.toggleFavorite(question.id);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 题目内容
                  Text(
                    question.content,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // 分类信息（使用格式化后的标题）
                  Text(
                    '${question.formattedLevel1Title} > ${question.formattedLevel2Title}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 标签
                  Wrap(
                    spacing: 4,
                    children: question.allTags.take(3).map((tag) {
                      return Chip(
                        label: Text(tag),
                        labelStyle: const TextStyle(fontSize: 10),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getPopularityColor(int popularity) {
    if (popularity >= 15) return Colors.red;
    if (popularity >= 10) return Colors.orange;
    if (popularity >= 5) return Colors.blue;
    return Colors.grey;
  }

  void _showFilterDialog() {
    final provider = Provider.of<StudyProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('筛选题目'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('按热度筛选:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('全部'),
                      selected: provider.minPopularity == 0,
                      onSelected: (_) {
                        provider.setMinPopularity(0);
                        Navigator.pop(context);
                      },
                    ),
                    FilterChip(
                      label: const Text('≥5校'),
                      selected: provider.minPopularity == 5,
                      onSelected: (_) {
                        provider.setMinPopularity(5);
                        Navigator.pop(context);
                      },
                    ),
                    FilterChip(
                      label: const Text('≥10校'),
                      selected: provider.minPopularity == 10,
                      onSelected: (_) {
                        provider.setMinPopularity(10);
                        Navigator.pop(context);
                      },
                    ),
                    FilterChip(
                      label: const Text('≥15校'),
                      selected: provider.minPopularity == 15,
                      onSelected: (_) {
                        provider.setMinPopularity(15);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('按标签筛选:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: provider.allTags.map((tag) {
                    return FilterChip(
                      label: Text(tag),
                      selected: provider.filterTag == tag,
                      onSelected: (_) {
                        provider.setFilterTag(
                          provider.filterTag == tag ? '' : tag,
                        );
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                provider.clearFilters();
                Navigator.pop(context);
              },
              child: const Text('清除筛选'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }
}
