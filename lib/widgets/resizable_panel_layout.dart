import 'package:flutter/material.dart';
import 'resizable_panel_divider.dart';

class ResizablePanelLayout extends StatefulWidget {
  final Widget? leftPanel;
  final Widget middlePanel;
  final Widget? rightPanel;
  final double initialLeftPanelWeight;
  final double initialRightPanelWeight;
  final double minLeftPanelWidth;
  final double minMiddlePanelWidth;
  final double minRightPanelWidth;
  final bool showLeftPanel;
  final bool showRightPanel;
  final Function(double, double, double)? onLayoutChanged;
  final double? savedLeftPanelWidth;
  final double? savedMiddlePanelWidth; 
  final double? savedRightPanelWidth;
  
  const ResizablePanelLayout({
    Key? key,
    this.leftPanel,
    required this.middlePanel,
    this.rightPanel,
    this.initialLeftPanelWeight = 0.2,
    this.initialRightPanelWeight = 0.4,
    this.minLeftPanelWidth = 100.0,
    this.minMiddlePanelWidth = 200.0,
    this.minRightPanelWidth = 200.0,
    this.showLeftPanel = true,
    this.showRightPanel = true,
    this.onLayoutChanged,
    this.savedLeftPanelWidth,
    this.savedMiddlePanelWidth,
    this.savedRightPanelWidth,
  }) : super(key: key);

  @override
  State<ResizablePanelLayout> createState() => _ResizablePanelLayoutState();
}

class _ResizablePanelLayoutState extends State<ResizablePanelLayout> {
  late double _leftPanelWidth;
  late double _middlePanelWidth;
  late double _rightPanelWidth;
  double _totalWidth = 0; // 初始化为0，而不是使用late
  bool _isInitialized = false; // 添加初始化标志
  
  // 计算初始宽度
  void _calculateInitialWidths(double totalWidth) {
    if (_isInitialized && _totalWidth > 0) {
      // 如果已经初始化过并且总宽度不变，则不重新计算
      if (_totalWidth == totalWidth) return;
      
      // 如果总宽度改变，按比例调整各个面板的宽度
      double ratio = totalWidth / _totalWidth;
      _leftPanelWidth *= ratio;
      _middlePanelWidth *= ratio;
      _rightPanelWidth *= ratio;
      _totalWidth = totalWidth;
      _applyMinWidthLimits();
      return;
    }
    
    _totalWidth = totalWidth;
    _isInitialized = true;
    
    // 优先使用保存的宽度
    if (widget.savedLeftPanelWidth != null && 
        widget.savedMiddlePanelWidth != null && 
        widget.savedRightPanelWidth != null) {
      _leftPanelWidth = widget.showLeftPanel ? widget.savedLeftPanelWidth! : 0;
      _middlePanelWidth = widget.savedMiddlePanelWidth!;
      _rightPanelWidth = widget.showRightPanel ? widget.savedRightPanelWidth! : 0;
      
      // 根据可见性调整宽度
      if (!widget.showLeftPanel) {
        _middlePanelWidth = _middlePanelWidth + _leftPanelWidth;
        _leftPanelWidth = 0;
      }
      
      if (!widget.showRightPanel) {
        _middlePanelWidth = _middlePanelWidth + _rightPanelWidth;
        _rightPanelWidth = 0;
      }
      
      // 确保宽度总和不超过总宽度
      double totalPanelWidth = _leftPanelWidth + _middlePanelWidth + _rightPanelWidth;
      if (totalPanelWidth > totalWidth) {
        double ratio = totalWidth / totalPanelWidth;
        _leftPanelWidth *= ratio;
        _middlePanelWidth *= ratio;
        _rightPanelWidth *= ratio;
      }
    } else {
      // 使用权重计算宽度
      if (widget.showLeftPanel && widget.showRightPanel) {
        // 所有面板都显示
        _leftPanelWidth = totalWidth * widget.initialLeftPanelWeight;
        _rightPanelWidth = totalWidth * widget.initialRightPanelWeight;
        _middlePanelWidth = totalWidth - _leftPanelWidth - _rightPanelWidth - 16.0; // 减去两个分隔线的宽度
      } else if (widget.showLeftPanel) {
        // 只显示左侧和中间面板
        _leftPanelWidth = totalWidth * widget.initialLeftPanelWeight;
        _middlePanelWidth = totalWidth - _leftPanelWidth - 8.0; // 减去一个分隔线的宽度
        _rightPanelWidth = 0;
      } else if (widget.showRightPanel) {
        // 只显示中间和右侧面板
        _rightPanelWidth = totalWidth * widget.initialRightPanelWeight;
        _middlePanelWidth = totalWidth - _rightPanelWidth - 8.0; // 减去一个分隔线的宽度
        _leftPanelWidth = 0;
      } else {
        // 只显示中间面板
        _middlePanelWidth = totalWidth;
        _leftPanelWidth = 0;
        _rightPanelWidth = 0;
      }
    }
    
    // 确保最小宽度限制
    _applyMinWidthLimits();
  }
  
  // 应用最小宽度限制
  void _applyMinWidthLimits() {
    if (widget.showLeftPanel && _leftPanelWidth < widget.minLeftPanelWidth) {
      _leftPanelWidth = widget.minLeftPanelWidth;
    }
    
    if (_middlePanelWidth < widget.minMiddlePanelWidth) {
      _middlePanelWidth = widget.minMiddlePanelWidth;
    }
    
    if (widget.showRightPanel && _rightPanelWidth < widget.minRightPanelWidth) {
      _rightPanelWidth = widget.minRightPanelWidth;
    }
    
    // 确保总宽度不超过可用宽度
    double totalPanelWidth = _leftPanelWidth + _middlePanelWidth + _rightPanelWidth;
    double dividerWidth = (widget.showLeftPanel ? 8.0 : 0.0) + (widget.showRightPanel ? 8.0 : 0.0);
    
    if (totalPanelWidth + dividerWidth > _totalWidth) {
      // 按比例缩减
      double excessWidth = totalPanelWidth + dividerWidth - _totalWidth;
      double ratio = excessWidth / totalPanelWidth;
      
      if (widget.showLeftPanel) {
        _leftPanelWidth -= _leftPanelWidth * ratio;
      }
      
      _middlePanelWidth -= _middlePanelWidth * ratio;
      
      if (widget.showRightPanel) {
        _rightPanelWidth -= _rightPanelWidth * ratio;
      }
    }
  }
  
  // 处理左侧分隔线拖动
  void _handleLeftDividerDrag(double delta) {
    if (delta == 0) return; // 忽略无变化的拖动
    
    setState(() {
      // 计算新的面板宽度
      double newLeftWidth = _leftPanelWidth + delta;
      double newMiddleWidth = _middlePanelWidth - delta;
      
      // 限制最小宽度
      if (newLeftWidth < widget.minLeftPanelWidth) {
        newLeftWidth = widget.minLeftPanelWidth;
        newMiddleWidth = _middlePanelWidth - (newLeftWidth - _leftPanelWidth);
      }
      
      if (newMiddleWidth < widget.minMiddlePanelWidth) {
        newMiddleWidth = widget.minMiddlePanelWidth;
        newLeftWidth = _leftPanelWidth + (_middlePanelWidth - newMiddleWidth);
      }
      
      // 限制最大宽度 (不超过总宽度的70%)
      double maxLeftWidth = _totalWidth * 0.7;
      double maxMiddleWidth = _totalWidth * 0.8;
      
      if (newLeftWidth > maxLeftWidth) {
        newLeftWidth = maxLeftWidth;
        newMiddleWidth = _middlePanelWidth - (newLeftWidth - _leftPanelWidth);
      }
      
      if (newMiddleWidth > maxMiddleWidth) {
        newMiddleWidth = maxMiddleWidth;
        newLeftWidth = _leftPanelWidth + (_middlePanelWidth - newMiddleWidth);
      }
      
      // 应用新的宽度
      _leftPanelWidth = newLeftWidth;
      _middlePanelWidth = newMiddleWidth;
      
      // 通知布局变化
      if (widget.onLayoutChanged != null) {
        widget.onLayoutChanged!(_leftPanelWidth, _middlePanelWidth, _rightPanelWidth);
      }
    });
  }
  
  // 处理右侧分隔线拖动
  void _handleRightDividerDrag(double delta) {
    if (delta == 0) return; // 忽略无变化的拖动
    
    setState(() {
      // 计算新的面板宽度
      double newMiddleWidth = _middlePanelWidth + delta;
      double newRightWidth = _rightPanelWidth - delta;
      
      // 限制最小宽度
      if (newMiddleWidth < widget.minMiddlePanelWidth) {
        newMiddleWidth = widget.minMiddlePanelWidth;
        newRightWidth = _rightPanelWidth - (newMiddleWidth - _middlePanelWidth);
      }
      
      if (newRightWidth < widget.minRightPanelWidth) {
        newRightWidth = widget.minRightPanelWidth;
        newMiddleWidth = _middlePanelWidth + (_rightPanelWidth - newRightWidth);
      }
      
      // 限制最大宽度 (不超过总宽度的70%)
      double maxMiddleWidth = _totalWidth * 0.8;
      double maxRightWidth = _totalWidth * 0.7;
      
      if (newMiddleWidth > maxMiddleWidth) {
        newMiddleWidth = maxMiddleWidth;
        newRightWidth = _rightPanelWidth - (newMiddleWidth - _middlePanelWidth);
      }
      
      if (newRightWidth > maxRightWidth) {
        newRightWidth = maxRightWidth;
        newMiddleWidth = _middlePanelWidth + (_rightPanelWidth - newRightWidth);
      }
      
      // 应用新的宽度
      _middlePanelWidth = newMiddleWidth;
      _rightPanelWidth = newRightWidth;
      
      // 通知布局变化
      if (widget.onLayoutChanged != null) {
        widget.onLayoutChanged!(_leftPanelWidth, _middlePanelWidth, _rightPanelWidth);
      }
    });
  }
  
  // 重置面板布局
  void _resetLayout() {
    setState(() {
      // 重置初始化标志
      _isInitialized = false;
      
      // 使用默认权重计算新的宽度
      if (widget.showLeftPanel && widget.showRightPanel) {
        _leftPanelWidth = _totalWidth * widget.initialLeftPanelWeight;
        _rightPanelWidth = _totalWidth * widget.initialRightPanelWeight;
        _middlePanelWidth = _totalWidth - _leftPanelWidth - _rightPanelWidth - 16.0;
      } else if (widget.showLeftPanel) {
        _leftPanelWidth = _totalWidth * widget.initialLeftPanelWeight;
        _middlePanelWidth = _totalWidth - _leftPanelWidth - 8.0;
        _rightPanelWidth = 0;
      } else if (widget.showRightPanel) {
        _rightPanelWidth = _totalWidth * widget.initialRightPanelWeight;
        _middlePanelWidth = _totalWidth - _rightPanelWidth - 8.0;
        _leftPanelWidth = 0;
      } else {
        _middlePanelWidth = _totalWidth;
        _leftPanelWidth = 0;
        _rightPanelWidth = 0;
      }
      
      // 应用最小宽度限制
      _applyMinWidthLimits();
      
      // 重新设置为已初始化状态
      _isInitialized = true;
      
      // 通知布局变化
      if (widget.onLayoutChanged != null) {
        widget.onLayoutChanged!(_leftPanelWidth, _middlePanelWidth, _rightPanelWidth);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 初始化或窗口大小变化时计算宽度
        _calculateInitialWidths(constraints.maxWidth);
        
        return Row(
          children: [
            // 左侧面板
            if (widget.showLeftPanel) ...[
              SizedBox(
                width: _leftPanelWidth,
                child: widget.leftPanel,
              ),
              ResizablePanelDivider(
                onDrag: _handleLeftDividerDrag,
                onDoubleTap: _resetLayout,
              ),
            ],
            
            // 中间面板
            SizedBox(
              width: _middlePanelWidth,
              child: widget.middlePanel,
            ),
            
            // 右侧面板
            if (widget.showRightPanel) ...[
              ResizablePanelDivider(
                onDrag: _handleRightDividerDrag,
                onDoubleTap: _resetLayout,
              ),
              SizedBox(
                width: _rightPanelWidth,
                child: widget.rightPanel,
              ),
            ],
          ],
        );
      },
    );
  }
} 