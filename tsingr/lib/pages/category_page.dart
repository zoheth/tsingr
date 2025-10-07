import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/study_provider.dart';
import '../models/question.dart';
import 'question_detail_page.dart';

/// 分类导航页面 - 提供目录式的题目浏览方式
class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  String? _selectedLevel1;
  String? _selectedLevel2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildTitle(),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: _buildLeading(),
      ),
      body: Consumer<StudyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // 响应式布局：根据屏幕宽度选择布局方式
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth > 600;

              if (isWideScreen) {
                // 宽屏：三栏布局
                return _buildThreeColumnLayout(provider);
              } else {
                // 窄屏：单页导航
                return _buildSingleColumnNavigation(provider);
              }
            },
          );
        },
      ),
    );
  }

  /// AppBar标题（动态显示当前位置）
  Widget _buildTitle() {
    if (_selectedLevel2 != null) {
      return Text(
        Question.formatTitle(_selectedLevel2!, false),
        style: const TextStyle(fontSize: 16),
      );
    } else if (_selectedLevel1 != null) {
      return Text(Question.formatTitle(_selectedLevel1!, true));
    } else {
      return const Text('按分类浏览');
    }
  }

  /// AppBar返回按钮（窄屏时支持层级返回）
  Widget? _buildLeading() {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        if (_selectedLevel2 != null) {
          setState(() => _selectedLevel2 = null);
        } else if (_selectedLevel1 != null) {
          setState(() => _selectedLevel1 = null);
        } else {
          Navigator.pop(context);
        }
      },
    );
  }

  /// 三栏布局（平板/桌面）
  Widget _buildThreeColumnLayout(StudyProvider provider) {
    return Row(
      children: [
        // 左侧：一级分类列表
        Expanded(
          flex: 3,
          child: _buildLevel1List(provider),
        ),
        const VerticalDivider(width: 1),

        // 中间：二级分类列表
        if (_selectedLevel1 != null)
          Expanded(
            flex: 3,
            child: _buildLevel2List(provider),
          ),
        if (_selectedLevel1 != null) const VerticalDivider(width: 1),

        // 右侧：题目列表
        if (_selectedLevel2 != null)
          Expanded(
            flex: 4,
            child: _buildQuestionList(provider),
          ),
      ],
    );
  }

  /// 单列导航（手机）
  Widget _buildSingleColumnNavigation(StudyProvider provider) {
    if (_selectedLevel2 != null) {
      // 显示题目列表
      return _buildQuestionList(provider);
    } else if (_selectedLevel1 != null) {
      // 显示二级分类
      return _buildLevel2List(provider);
    } else {
      // 显示一级分类
      return _buildLevel1List(provider);
    }
  }

  /// 一级分类列表
  Widget _buildLevel1List(StudyProvider provider) {
    final categories = provider.allLevel1Categories;

    return Container(
      color: Colors.grey[50],
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedLevel1 == category;
          final questionCount = provider.allQuestions
              .where((q) => q.level1Title == category)
              .length;

          return ListTile(
            selected: isSelected,
            selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            leading: Icon(
              Icons.folder,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[600],
            ),
            title: Text(
              Question.formatTitle(category, true),
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.black87,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                questionCount.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              setState(() {
                _selectedLevel1 = category;
                _selectedLevel2 = null; // 重置二级分类选择
              });
            },
          );
        },
      ),
    );
  }

  /// 二级分类列表
  Widget _buildLevel2List(StudyProvider provider) {
    final categories = provider.allQuestions
        .where((q) => q.level1Title == _selectedLevel1)
        .map((q) => q.level2Title)
        .toSet()
        .toList();

    // 按序号排序
    categories.sort((a, b) {
      final orderA = Question.extractOrderNumber(a, false);
      final orderB = Question.extractOrderNumber(b, false);
      return orderA.compareTo(orderB);
    });

    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          // 面包屑导航
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.arrow_forward, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    Question.formatTitle(_selectedLevel1!, true),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // 二级分类列表
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedLevel2 == category;
                final questionCount = provider.allQuestions
                    .where((q) =>
                        q.level1Title == _selectedLevel1 &&
                        q.level2Title == category)
                    .length;

                return ListTile(
                  selected: isSelected,
                  selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  leading: Icon(
                    Icons.folder_open,
                    size: 20,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[500],
                  ),
                  title: Text(
                    Question.formatTitle(category, false),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black87,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      questionCount.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedLevel2 = category;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 题目列表
  Widget _buildQuestionList(StudyProvider provider) {
    final questions = provider.allQuestions
        .where((q) =>
            q.level1Title == _selectedLevel1 &&
            q.level2Title == _selectedLevel2)
        .toList();

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 面包屑导航
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.list, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        Question.formatTitle(_selectedLevel2!, false),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '共 ${questions.length} 道题目',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // 题目列表
          Expanded(
            child: questions.isEmpty
                ? const Center(child: Text('暂无题目'))
                : ListView.builder(
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final question = questions[index];
                      return _buildQuestionItem(question, provider);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 题目卡片
  Widget _buildQuestionItem(Question question, StudyProvider provider) {
    final record = provider.getRecord(question.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1,
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
              // 头部：热度和学习状态
              Row(
                children: [
                  // 热度标签
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPopularityColor(question.popularity),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '🔥 ${question.popularity}校',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 已学习标记
                  if (record.studyCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '✓ ${record.studyCount}次',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),

                  const Spacer(),

                  // 收藏按钮
                  IconButton(
                    icon: Icon(
                      record.isFavorite ? Icons.star : Icons.star_border,
                      color: record.isFavorite ? Colors.amber : Colors.grey,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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
                  fontSize: 14,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // 标签
              if (question.allTags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: question.allTags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getPopularityColor(int popularity) {
    if (popularity >= 15) return Colors.red;
    if (popularity >= 10) return Colors.orange;
    if (popularity >= 5) return Colors.blue;
    return Colors.grey;
  }
}
