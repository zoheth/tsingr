import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../providers/study_provider.dart';

class QuestionDetailPage extends StatefulWidget {
  final Question question;

  const QuestionDetailPage({super.key, required this.question});

  @override
  State<QuestionDetailPage> createState() => _QuestionDetailPageState();
}

class _QuestionDetailPageState extends State<QuestionDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _answerController;
  late TextEditingController _notesController;
  bool _isEditingAnswer = false;
  bool _isEditingNotes = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 从provider获取初始数据
    final provider = Provider.of<StudyProvider>(context, listen: false);
    final record = provider.getRecord(widget.question.id);
    _answerController = TextEditingController(text: record.answer);
    _notesController = TextEditingController(text: record.notes);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _answerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('题目详情'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<StudyProvider>(
            builder: (context, provider, child) {
              final record = provider.getRecord(widget.question.id);
              return IconButton(
                icon: Icon(
                  record.isFavorite ? Icons.star : Icons.star_border,
                  color: record.isFavorite ? Colors.amber : null,
                ),
                onPressed: () {
                  provider.toggleFavorite(widget.question.id);
                },
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '题目信息', icon: Icon(Icons.info_outline)),
            Tab(text: '我的学习', icon: Icon(Icons.edit_note)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuestionInfoTab(),
          _buildStudyTab(),
        ],
      ),
      bottomNavigationBar: Consumer<StudyProvider>(
        builder: (context, provider, child) {
          final record = provider.getRecord(widget.question.id);
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () async {
                await provider.markAsStudied(widget.question.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('已完成学习！总共学习 ${record.studyCount + 1} 次'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                '标记为已学习',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }

  // 题目信息标签页
  Widget _buildQuestionInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 题目内容
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '题目内容',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.question.content,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 分类信息
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '分类',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('一级分类', widget.question.formattedLevel1Title),
                  _buildInfoRow('二级分类', widget.question.formattedLevel2Title),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 统计信息
          Consumer<StudyProvider>(
            builder: (context, provider, child) {
              final record = provider.getRecord(widget.question.id);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '统计信息',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('热度', '${widget.question.popularity} 个学校考过'),
                      _buildInfoRow('学习次数', '${record.studyCount} 次'),
                      if (record.lastStudyTime != null)
                        _buildInfoRow(
                          '上次学习',
                          _formatDateTime(record.lastStudyTime!),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // 考试记录
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '考试记录',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text('${widget.question.appearances.length} 条'),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...widget.question.appearances.map((app) {
                    return _buildAppearanceCard(app);
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 标签
          if (widget.question.allTags.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '标签',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.question.allTags.map((tag) {
                        return Chip(label: Text(tag));
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 我的学习标签页（作答和笔记）
  Widget _buildStudyTab() {
    return Consumer<StudyProvider>(
      builder: (context, provider, child) {
        final record = provider.getRecord(widget.question.id);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 我的作答
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit, size: 20, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            '我的作答',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (!_isEditingAnswer && record.answer.isNotEmpty)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isEditingAnswer = true;
                                });
                              },
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('编辑'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_isEditingAnswer || record.answer.isEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _answerController,
                              maxLines: 10,
                              decoration: const InputDecoration(
                                hintText: '在此输入你的答案...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    _answerController.text = record.answer;
                                    setState(() {
                                      _isEditingAnswer = false;
                                    });
                                  },
                                  child: const Text('取消'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    await provider.updateAnswer(
                                      widget.question.id,
                                      _answerController.text,
                                    );
                                    setState(() {
                                      _isEditingAnswer = false;
                                    });
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('作答已保存'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('保存'),
                                ),
                              ],
                            ),
                          ],
                        )
                      else
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isEditingAnswer = true;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              record.answer,
                              style: const TextStyle(fontSize: 15, height: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 我的笔记
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.note, size: 20, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            '我的笔记',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (!_isEditingNotes && record.notes.isNotEmpty)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isEditingNotes = true;
                                });
                              },
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('编辑'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_isEditingNotes || record.notes.isEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _notesController,
                              maxLines: 10,
                              decoration: const InputDecoration(
                                hintText: '在此记录学习笔记、解题思路、知识点等...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    _notesController.text = record.notes;
                                    setState(() {
                                      _isEditingNotes = false;
                                    });
                                  },
                                  child: const Text('取消'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    await provider.updateNotes(
                                      widget.question.id,
                                      _notesController.text,
                                    );
                                    setState(() {
                                      _isEditingNotes = false;
                                    });
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('笔记已保存'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('保存'),
                                ),
                              ],
                            ),
                          ],
                        )
                      else
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isEditingNotes = true;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              record.notes,
                              style: const TextStyle(fontSize: 15, height: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceCard(Appearance app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (app.year.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    app.year,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (app.year.isNotEmpty) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  app.school.isNotEmpty ? app.school : '未知学校',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (app.majorCode.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '专业代码: ${app.majorCode}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
          if (app.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: app.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  labelStyle: const TextStyle(fontSize: 10),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
          if (app.notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '备注: ${app.notes}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
