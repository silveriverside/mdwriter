import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  final Function(bool)? onDragStart; // 添加这行
  final Function()? onDragEnd;       // 添加这行
  
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
    this.onDragStart,
    this.onDragEnd,
  }) : super(key: key);

  @override
  State<ResizablePanelLayout> createState() => _ResizablePanelLayoutState();
}

class _ResizablePanelLayoutState extends State<ResizablePanelLayout> {
  late double _leftPanelWidth;
  late double _middlePanelWidth;
  late double _rightPanelWidth;
  double _totalWidth = 0;
  bool _isInitialized = false;
  bool? _previousShowLeftPanel;
  bool? _previousShowRightPanel;
  
  // 计算初始宽度
  void _calculateInitialWidths(double totalWidth) {
    // 更新总宽度
    _totalWidth = totalWidth;

    bool needsRecalculation = !_isInitialized || 
                            _totalWidth != totalWidth ||
                            _previousShowLeftPanel != widget.showLeftPanel ||
                            _previousShowRightPanel != widget.showRightPanel;

    if (!needsRecalculation) return;

    // 如果面板显示状态发生变化，重新分配空间
    if (_isInitialized) {
      if (!widget.showLeftPanel && _previousShowLeftPanel == true) {
        // 左面板被隐藏，将其宽度分配给中间面板
        _middlePanelWidth += _leftPanelWidth;
        _leftPanelWidth = 0;
      } else if (widget.showLeftPanel && _previousShowLeftPanel == false) {
        // 左面板从隐藏变为显示，从中间面板分配空间
        double newLeftWidth = _totalWidth * widget.initialLeftPanelWeight;
        if (newLeftWidth > _middlePanelWidth * 0.7) {
          newLeftWidth = _middlePanelWidth * 0.7;
        }
        _leftPanelWidth = newLeftWidth;
        _middlePanelWidth -= newLeftWidth;
      }
      
      if (!widget.showRightPanel && _previousShowRightPanel == true) {
        // 右面板被隐藏，将其宽度分配给中间面板
        _middlePanelWidth += _rightPanelWidth;
        _rightPanelWidth = 0;
      } else if (widget.showRightPanel && _previousShowRightPanel == false) {
        // 右面板从隐藏变为显示，从中间面板分配空间
        double newRightWidth = _totalWidth * widget.initialRightPanelWeight;
        if (newRightWidth > _middlePanelWidth * 0.7) {
          newRightWidth = _middlePanelWidth * 0.7;
        }
        _rightPanelWidth = newRightWidth;
        _middlePanelWidth -= newRightWidth;
      }
    }
    
    // 保存当前的显示状态 - 确保在处理完可见性变化后更新
    _previousShowLeftPanel = widget.showLeftPanel;
    _previousShowRightPanel = widget.showRightPanel;
    
    if (!_isInitialized) {
      // 首次初始化
      if (widget.savedLeftPanelWidth != null && 
          widget.savedMiddlePanelWidth != null && 
          widget.savedRightPanelWidth != null) {
        _leftPanelWidth = widget.showLeftPanel ? widget.savedLeftPanelWidth! : 0;
        _middlePanelWidth = widget.savedMiddlePanelWidth!;
        _rightPanelWidth = widget.showRightPanel ? widget.savedRightPanelWidth! : 0;
        
        // 如果面板被隐藏，将其宽度分配给中间面板
        if (!widget.showLeftPanel) {
          _middlePanelWidth += _leftPanelWidth;
          _leftPanelWidth = 0;
        }
        if (!widget.showRightPanel) {
          _middlePanelWidth += _rightPanelWidth;
          _rightPanelWidth = 0;
        }
      } else {
        // 使用默认权重
        _initializeWithDefaultWeights(totalWidth);
      }
    } else {
      // 窗口大小改变，按比例调整
      double ratio = totalWidth / _totalWidth;
      _leftPanelWidth *= ratio;
      _middlePanelWidth *= ratio;
      _rightPanelWidth *= ratio;
    }
    
    // 调整面板宽度，确保总宽度不超过可用宽度
    double totalPanelWidth = _leftPanelWidth + _middlePanelWidth + _rightPanelWidth;
    double dividerWidth = (widget.showLeftPanel ? 8.0 : 0.0) + (widget.showRightPanel ? 8.0 : 0.0);
    if (totalPanelWidth + dividerWidth > _totalWidth) {
      double excessWidth = totalPanelWidth + dividerWidth - _totalWidth;
      double ratio = excessWidth / totalPanelWidth;

      // 按比例缩减面板宽度
      _leftPanelWidth -= _leftPanelWidth * ratio;
      _middlePanelWidth -= _middlePanelWidth * ratio;
      _rightPanelWidth -= _rightPanelWidth * ratio;
    }
    
    // 确保所有宽度都是大于等于0的，避免负值导致布局错误
    _leftPanelWidth = _leftPanelWidth.isNegative ? 0 : _leftPanelWidth;
    _middlePanelWidth = _middlePanelWidth.isNegative ? 0 : _middlePanelWidth;
    _rightPanelWidth = _rightPanelWidth.isNegative ? 0 : _rightPanelWidth;
    
    _applyMinWidthLimits();
    _isInitialized = true;
    
    // 通知布局变化
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (widget.onLayoutChanged != null) {
        widget.onLayoutChanged!(_leftPanelWidth, _middlePanelWidth, _rightPanelWidth);
      }
    });

    // 调试信息
    print('总宽度: $_totalWidth, 左面板宽度: $_leftPanelWidth, 中间面板宽度: $_middlePanelWidth, 右面板宽度: $_rightPanelWidth');
  }
  
  // 使用默认权重初始化
  void _initializeWithDefaultWeights(double totalWidth) {
    double dividerWidth = (widget.showLeftPanel ? 8.0 : 0.0) + (widget.showRightPanel ? 8.0 : 0.0);
    double availableWidth = totalWidth - dividerWidth;
    
    // 根据可用宽度的比例设置面板宽度
    if (widget.showLeftPanel && widget.showRightPanel) {
      _leftPanelWidth = availableWidth * widget.initialLeftPanelWeight;
      _rightPanelWidth = availableWidth * widget.initialRightPanelWeight;
      _middlePanelWidth = availableWidth - _leftPanelWidth - _rightPanelWidth;
    } else if (widget.showLeftPanel) {
      _leftPanelWidth = availableWidth * widget.initialLeftPanelWeight;
      _middlePanelWidth = availableWidth - _leftPanelWidth;
      _rightPanelWidth = 0;
    } else if (widget.showRightPanel) {
      _rightPanelWidth = availableWidth * widget.initialRightPanelWeight;
      _middlePanelWidth = availableWidth - _rightPanelWidth;
      _leftPanelWidth = 0;
    } else {
      _middlePanelWidth = availableWidth;
      _leftPanelWidth = 0;
      _rightPanelWidth = 0;
    }
    
    // 确保所有宽度都是大于等于0的，避免负值导致布局错误
    _leftPanelWidth = _leftPanelWidth.isNegative ? 0 : _leftPanelWidth;
    _middlePanelWidth = _middlePanelWidth.isNegative ? 0 : _middlePanelWidth;
    _rightPanelWidth = _rightPanelWidth.isNegative ? 0 : _rightPanelWidth;
  }
  
  // 应用最小宽度限制
  void _applyMinWidthLimits() {
    // 计算可用宽度
    double totalPanelWidth = _leftPanelWidth + _middlePanelWidth + _rightPanelWidth;
    double dividerWidth = (widget.showLeftPanel ? 8.0 : 0.0) + (widget.showRightPanel ? 8.0 : 0.0);

    // 确保总宽度不超过可用宽度
    if (totalPanelWidth + dividerWidth > _totalWidth) {
        double excessWidth = totalPanelWidth + dividerWidth - _totalWidth;
        double ratio = excessWidth / totalPanelWidth;

        // 按比例缩减面板宽度
        _leftPanelWidth -= _leftPanelWidth * ratio;
        _middlePanelWidth -= _middlePanelWidth * ratio;
        _rightPanelWidth -= _rightPanelWidth * ratio;
    }

    // 调试信息
    print('应用宽度限制后: 左面板宽度: $_leftPanelWidth, 中间面板宽度: $_middlePanelWidth, 右面板宽度: $_rightPanelWidth');
  }
  
  // 重置面板布局
  void _resetLayout() {
    setState(() {
      // 重置初始化标志，强制重新计算
      _isInitialized = false;
      
      // 重新计算面板宽度
      double dividerWidth = (widget.showLeftPanel ? 8.0 : 0.0) + (widget.showRightPanel ? 8.0 : 0.0);
      double availableWidth = _totalWidth - dividerWidth;
      
      if (widget.showLeftPanel && widget.showRightPanel) {
        _leftPanelWidth = availableWidth * widget.initialLeftPanelWeight;
        _rightPanelWidth = availableWidth * widget.initialRightPanelWeight;
        _middlePanelWidth = availableWidth - _leftPanelWidth - _rightPanelWidth;
      } else if (widget.showLeftPanel) {
        _leftPanelWidth = availableWidth * widget.initialLeftPanelWeight;
        _middlePanelWidth = availableWidth - _leftPanelWidth;
        _rightPanelWidth = 0;
      } else if (widget.showRightPanel) {
        _rightPanelWidth = availableWidth * widget.initialRightPanelWeight;
        _middlePanelWidth = availableWidth - _rightPanelWidth;
        _leftPanelWidth = 0;
      } else {
        _middlePanelWidth = availableWidth;
        _leftPanelWidth = 0;
        _rightPanelWidth = 0;
      }
      
      // 应用最小宽度限制
      _applyMinWidthLimits();
      
      // 重新设置为已初始化状态
      _isInitialized = true;
      
      // 通知布局变化
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (widget.onLayoutChanged != null) {
          widget.onLayoutChanged!(_leftPanelWidth, _middlePanelWidth, _rightPanelWidth);
        }
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 初始化或窗口大小变化时计算宽度
        _calculateInitialWidths(constraints.maxWidth);
        
        // 创建实际的布局
        return Row(
          children: [
            // 左侧面板
            if (widget.showLeftPanel) ...[
              Expanded(
                flex: (_leftPanelWidth / _totalWidth * 100).round(),
                child: SizedBox(
                  width: _leftPanelWidth,
                  child: widget.leftPanel,
                ),
              ),
              ResizablePanelDivider(
                onDrag: (delta) {
                  if (delta == 0) return;
                  _handleLeftDividerDrag(delta);
                  setState(() {});
                },
                onDragStateChanged: (isDragging) {
                  if (isDragging) {
                    widget.onDragStart?.call(true);
                  } else {
                    widget.onDragEnd?.call();
                  }
                },
                onDoubleTap: _resetLayout,
              ),
            ],
            
            // 中间面板 - 始终显示，宽度根据可见的面板动态调整
            Expanded(
              flex: (_middlePanelWidth / _totalWidth * 100).round(),
              child: SizedBox(
                width: _middlePanelWidth,
                child: widget.middlePanel,
              ),
            ),
            
            // 右侧面板
            if (widget.showRightPanel) ...[
              ResizablePanelDivider(
                onDrag: (delta) {
                  if (delta == 0) return;
                  _handleRightDividerDrag(delta);
                  setState(() {});
                },
                onDragStateChanged: (isDragging) {
                  if (isDragging) {
                    widget.onDragStart?.call(true);
                  } else {
                    widget.onDragEnd?.call();
                  }
                },
                onDoubleTap: _resetLayout,
              ),
              Expanded(
                flex: (_rightPanelWidth / _totalWidth * 100).round(),
                child: SizedBox(
                  width: _rightPanelWidth,
                  child: widget.rightPanel,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // 处理左侧分隔线拖动
  void _handleLeftDividerDrag(double delta) {
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
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (widget.onLayoutChanged != null) {
        widget.onLayoutChanged!(_leftPanelWidth, _middlePanelWidth, _rightPanelWidth);
      }
    });
  }

  // 处理右侧分隔线拖动
  void _handleRightDividerDrag(double delta) {
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
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (widget.onLayoutChanged != null) {
        widget.onLayoutChanged!(_leftPanelWidth, _middlePanelWidth, _rightPanelWidth);
      }
    });
  }
} 