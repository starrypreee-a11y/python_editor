import 'package:flutter/material.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/python.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Python Skeleton Editor',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      ),
      home: const EditorPage(),
    );
  }
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late CodeController _codeController;
  String _currentFilePath = '';
  List<Map<String, dynamic>> _outlineItems = [];

  // 默认骨架代码
  final String _defaultSkeleton = '''# === 模块导入 ===
import os
import sys

# === 全局变量 ===
API_KEY = ""  # 请填写你的API Key
CHANNEL = ""  # 请填写Channel名称

# === 函数：数据加载 ===
def load_data(file_path):
    """加载数据"""
    # TODO: 实现数据加载逻辑
    return data

# === 函数：数据处理 ===
def process_data(data, action):
    """处理数据"""
    # TODO: 实现数据处理逻辑
    return processed_data

# === 函数：结果输出 ===
def save_result(data, output_path):
    """保存结果"""
    # TODO: 实现结果保存逻辑
    pass

# === 主程序入口 ===
if __name__ == "__main__":
    # TODO: 主流程编排
    pass
''';

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: _defaultSkeleton,
      language: python,
    );
    _codeController.addListener(_updateOutline);
    _updateOutline();
  }

  @override
  void dispose() {
    _codeController.removeListener(_updateOutline);
    _codeController.dispose();
    super.dispose();
  }

  // 更新大纲：识别 # === xxx === 格式
  void _updateOutline() {
    final text = _codeController.text;
    final lines = text.split('\n');
    final List<Map<String, dynamic>> items = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      // 匹配 # === xxx === 格式
      final match = RegExp(r'^#\s*===\s*(.+?)\s*===\s*$').firstMatch(line);
      if (match != null) {
        items.add({
          'title': match.group(1)!,
          'line': i,
        });
      }
    }

    setState(() {
      _outlineItems = items;
    });
  }

  // 跳转到指定行
  void _jumpToLine(int lineNumber) {
    final text = _codeController.text;
    int position = 0;
    final lines = text.split('\n');
    
    for (int i = 0; i < lineNumber && i < lines.length; i++) {
      if (i > 0) position += 1; // 换行符
      position += lines[i].length;
    }
    
    _codeController.selection = TextSelection.collapsed(offset: position);
  }

  // 插入代码片段
  void _insertSnippet(String snippet) {
    final text = _codeController.text;
    final selection = _codeController.selection;
    final cursorPos = selection.baseOffset;

    // 计算当前行缩进
    int lineStart = text.lastIndexOf('\n', cursorPos - 1);
    if (lineStart == -1) lineStart = 0;
    String currentLine = text.substring(lineStart, cursorPos);
    RegExp indentReg = RegExp(r'^(\s*)');
    String indent = indentReg.firstMatch(currentLine)?.group(1) ?? '';

    // 缩进处理
    String indentedSnippet = snippet.split('\n').map((line) {
      return line.isEmpty ? line : indent + line;
    }).join('\n');

    // 插入
    final newText = text.replaceRange(
      cursorPos,
      cursorPos,
      indentedSnippet,
    );
    _codeController.text = newText;

    // 移动光标
    final newCursorPos = cursorPos + indentedSnippet.length;
    _codeController.selection = TextSelection.collapsed(offset: newCursorPos);
  }

  // 新建文件
  Future<void> _newFile() async {
    setState(() {
      _codeController.text = _defaultSkeleton;
      _currentFilePath = '';
    });
  }

  // 保存文件
  Future<void> _saveFile() async {
    if (_currentFilePath.isEmpty) {
      await _saveAsFile();
    } else {
      await File(_currentFilePath).writeAsString(_codeController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功')),
        );
      }
    }
  }

  // 另存为
  Future<void> _saveAsFile() async {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: '保存Python文件',
      fileName: 'script.py',
      allowedExtensions: ['py'],
    );
    
    if (outputFile != null) {
      await File(outputFile).writeAsString(_codeController.text);
      setState(() {
        _currentFilePath = outputFile;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已保存到: $outputFile')),
        );
      }
    }
  }

  // 打开文件
  Future<void> _openFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: '打开Python文件',
      allowedExtensions: ['py'],
    );
    
    if (result != null) {
      String filePath = result.files.single.path!;
      String content = await File(filePath).readAsString();
      setState(() {
        _codeController.text = content;
        _currentFilePath = filePath;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已打开: $filePath')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 左侧大纲面板
          Container(
            width: 260,
            color: const Color(0xFF252526),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '📑 代码大纲',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1, color: Colors.grey),
                Expanded(
                  child: _outlineItems.isEmpty
                      ? const Center(
                          child: Text(
                            '没有找到大纲\n\n使用 # === 标题 === 格式',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _outlineItems.length,
                          itemBuilder: (context, index) {
                            final item = _outlineItems[index];
                            return _OutlineItem(
                              title: item['title'],
                              lineNumber: item['line'] + 1,
                              onTap: () => _jumpToLine(item['line']),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          // 中间代码编辑区
          Expanded(
            child: Column(
              children: [
                // 工具栏
                Container(
                  padding: const EdgeInsets.all(8),
                  color: const Color(0xFF2D2D30),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ToolButton('📁 新建', _newFile),
                      _ToolButton('📂 打开', _openFile),
                      _ToolButton('💾 保存', _saveFile),
                      const SizedBox(width: 20),
                      _ToolButton('for循环', () => _insertSnippet(_forSnippet)),
                      _ToolButton('if判断', () => _insertSnippet(_ifSnippet)),
                      _ToolButton('打开文件', () => _insertSnippet(_openFileSnippet)),
                      _ToolButton('字典操作', () => _insertSnippet(_dictSnippet)),
                      _ToolButton('添加参数', () => _insertSnippet(_argSnippet)),
                    ],
                  ),
                ),
                // 代码编辑区 - 修复底部溢出问题
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: CodeField(
                            controller: _codeController,
                            textStyle: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // 右侧参数面板
          Container(
            width: 280,
            color: const Color(0xFF252526),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚙️ 参数配置',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  '💡 使用说明：',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                const Text('• 大纲标记：# === 标题 ===', style: TextStyle(fontSize: 12)),
                const Text('• 普通注释：# 不会进入大纲', style: TextStyle(fontSize: 12)),
                const Text('• 点击大纲跳转到对应位置', style: TextStyle(fontSize: 12)),
                const Divider(height: 24),
                const Text(
                  '🎨 参数颜色约定：',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                const Text('🟢 绿色：输入参数', style: TextStyle(color: Colors.green, fontSize: 12)),
                const Text('🔵 蓝色：输出参数', style: TextStyle(color: Colors.blue, fontSize: 12)),
                const Text('🟣 紫色：命令行参数', style: TextStyle(color: Colors.purple, fontSize: 12)),
                const Divider(height: 24),
                const Text(
                  '⌨️ 常用快捷键：',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                const Text('• Ctrl+S: 保存文件', style: TextStyle(fontSize: 12)),
                const Text('• Ctrl+O: 打开文件', style: TextStyle(fontSize: 12)),
                const Text('• Ctrl+N: 新建文件', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 代码片段模板
  final String _forSnippet = '''
for item in collection:
    # [循环体待实现]
    pass
''';

  final String _ifSnippet = '''
if condition:
    # [条件成立时执行]
    pass
else:
    # [条件不成立时执行]
    pass
''';

  final String _openFileSnippet = '''
with open(file_path, 'r') as f:
    content = f.read()
    # [处理文件内容]
''';

  final String _dictSnippet = '''
# 字典操作示例
my_dict = {}
my_dict['key'] = 'value'
value = my_dict.get('key', 'default')
''';

  final String _argSnippet = '''
parser.add_argument("-i", "--input", help="输入文件路径")
parser.add_argument("-o", "--output", help="输出文件路径")
parser.add_argument("-a", "--action", choices=["process", "analyze"])
''';
}

// 大纲条目组件
class _OutlineItem extends StatelessWidget {
  final String title;
  final int lineNumber;
  final VoidCallback onTap;

  const _OutlineItem({
    required this.title,
    required this.lineNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.code, size: 16, color: Colors.blue),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        ':$lineNumber',
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
      dense: true,
      onTap: onTap,
      hoverColor: Colors.blue.withOpacity(0.2),
    );
  }
}

// 工具栏按钮
class _ToolButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _ToolButton(this.label, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0E639C),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 32),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

