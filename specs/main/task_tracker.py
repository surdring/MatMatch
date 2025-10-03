"""
任务跟踪工具 - 智能物料查重工具项目
基于tasks.md文档的任务管理和进度跟踪工具
"""

import json
import re
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, asdict
from enum import Enum

class TaskStatus(Enum):
    """任务状态枚举"""
    NOT_STARTED = "not_started"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    BLOCKED = "blocked"
    CANCELLED = "cancelled"

class Priority(Enum):
    """任务优先级枚举"""
    P0 = "P0"  # 关键路径
    P1 = "P1"  # 重要
    P2 = "P2"  # 普通
    P3 = "P3"  # 低优先级

@dataclass
class Task:
    """任务数据类"""
    id: str
    title: str
    phase: str
    priority: Priority
    estimated_days: int
    assignee: str
    dependencies: List[str]
    status: TaskStatus = TaskStatus.NOT_STARTED
    start_date: Optional[str] = None
    end_date: Optional[str] = None
    completion_percentage: int = 0
    notes: str = ""
    
    def to_dict(self) -> Dict:
        """转换为字典格式"""
        data = asdict(self)
        data['priority'] = self.priority.value
        data['status'] = self.status.value
        return data
    
    @classmethod
    def from_dict(cls, data: Dict) -> 'Task':
        """从字典创建任务对象"""
        data['priority'] = Priority(data['priority'])
        data['status'] = TaskStatus(data['status'])
        return cls(**data)

class TaskTracker:
    """任务跟踪器"""
    
    def __init__(self, tasks_file: str = "task_progress.json"):
        self.tasks_file = Path(tasks_file)
        self.tasks: Dict[str, Task] = {}
        self.load_tasks()
        
    def load_tasks(self):
        """加载任务数据"""
        if self.tasks_file.exists():
            with open(self.tasks_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                self.tasks = {
                    task_id: Task.from_dict(task_data) 
                    for task_id, task_data in data.items()
                }
        else:
            self._initialize_default_tasks()
    
    def save_tasks(self):
        """保存任务数据"""
        data = {task_id: task.to_dict() for task_id, task in self.tasks.items()}
        with open(self.tasks_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
    
    def _initialize_default_tasks(self):
        """初始化默认任务列表"""
        default_tasks = [
            # Phase 1: 数据基础建设
            Task("1.1", "PostgreSQL数据库设计与实现", "Phase 1", Priority.P0, 3, "后端开发", []),
            Task("1.2", "Oracle数据源适配器实现", "Phase 1", Priority.P0, 2, "后端开发", []),
            Task("1.3", "ETL数据管道实现", "Phase 1", Priority.P0, 4, "后端开发", ["1.1", "1.2"]),
            
            # Phase 2: 核心算法实现
            Task("2.1", "通用物料处理器实现", "Phase 2", Priority.P0, 5, "算法开发", ["1.1"]),
            Task("2.2", "相似度计算算法实现", "Phase 2", Priority.P0, 4, "算法开发", ["2.1"]),
            Task("2.3", "规则和词典管理系统", "Phase 2", Priority.P1, 3, "后端开发", ["2.1"]),
            
            # Phase 3: API服务开发
            Task("3.1", "FastAPI核心服务框架", "Phase 3", Priority.P0, 2, "后端开发", ["1.1"]),
            Task("3.2", "批量查重API实现", "Phase 3", Priority.P0, 4, "后端开发", ["2.1", "2.2", "3.1"]),
            Task("3.3", "单条查重API实现", "Phase 3", Priority.P0, 2, "后端开发", ["2.1", "2.2", "3.1"]),
            Task("3.4", "管理后台API实现", "Phase 3", Priority.P1, 3, "后端开发", ["2.3", "3.1"]),
            
            # Phase 4: 前端界面开发
            Task("4.1", "Vue.js项目框架搭建", "Phase 4", Priority.P0, 2, "前端开发", []),
            Task("4.2", "物料查重界面实现", "Phase 4", Priority.P0, 4, "前端开发", ["4.1", "3.2", "3.3"]),
            Task("4.3", "管理后台界面实现", "Phase 4", Priority.P1, 4, "前端开发", ["4.1", "3.4"]),
            Task("4.4", "Pinia状态管理实现", "Phase 4", Priority.P1, 2, "前端开发", ["4.1"]),
            
            # Phase 5: 系统集成与优化
            Task("5.1", "系统集成测试", "Phase 5", Priority.P0, 3, "测试工程师", ["4.2", "4.3"]),
            Task("5.2", "性能优化与调优", "Phase 5", Priority.P1, 2, "后端开发", ["5.1"]),
            Task("5.3", "部署文档和用户手册", "Phase 5", Priority.P1, 2, "技术文档", ["5.1"]),
        ]
        
        for task in default_tasks:
            self.tasks[task.id] = task
        
        self.save_tasks()
    
    def update_task_status(self, task_id: str, status: TaskStatus, completion_percentage: int = None, notes: str = None):
        """更新任务状态"""
        if task_id not in self.tasks:
            raise ValueError(f"任务 {task_id} 不存在")
        
        task = self.tasks[task_id]
        task.status = status
        
        if completion_percentage is not None:
            task.completion_percentage = completion_percentage
        
        if notes is not None:
            task.notes = notes
        
        # 自动设置开始和结束时间
        now = datetime.now().strftime("%Y-%m-%d")
        if status == TaskStatus.IN_PROGRESS and not task.start_date:
            task.start_date = now
        elif status == TaskStatus.COMPLETED:
            task.end_date = now
            task.completion_percentage = 100
        
        self.save_tasks()
    
    def get_task_dependencies(self, task_id: str) -> List[Task]:
        """获取任务依赖"""
        if task_id not in self.tasks:
            return []
        
        dependencies = []
        for dep_id in self.tasks[task_id].dependencies:
            if dep_id in self.tasks:
                dependencies.append(self.tasks[dep_id])
        
        return dependencies
    
    def get_ready_tasks(self) -> List[Task]:
        """获取可以开始的任务（依赖已完成）"""
        ready_tasks = []
        
        for task in self.tasks.values():
            if task.status == TaskStatus.NOT_STARTED:
                dependencies = self.get_task_dependencies(task.id)
                if all(dep.status == TaskStatus.COMPLETED for dep in dependencies):
                    ready_tasks.append(task)
        
        return sorted(ready_tasks, key=lambda t: (t.priority.value, t.id))
    
    def get_critical_path(self) -> List[Task]:
        """获取关键路径任务"""
        return [task for task in self.tasks.values() if task.priority == Priority.P0]
    
    def get_phase_progress(self) -> Dict[str, Dict]:
        """获取各阶段进度"""
        phases = {}
        
        for task in self.tasks.values():
            if task.phase not in phases:
                phases[task.phase] = {
                    'total_tasks': 0,
                    'completed_tasks': 0,
                    'in_progress_tasks': 0,
                    'total_days': 0,
                    'completed_days': 0
                }
            
            phase_data = phases[task.phase]
            phase_data['total_tasks'] += 1
            phase_data['total_days'] += task.estimated_days
            
            if task.status == TaskStatus.COMPLETED:
                phase_data['completed_tasks'] += 1
                phase_data['completed_days'] += task.estimated_days
            elif task.status == TaskStatus.IN_PROGRESS:
                phase_data['in_progress_tasks'] += 1
                phase_data['completed_days'] += task.estimated_days * (task.completion_percentage / 100)
        
        # 计算进度百分比
        for phase_data in phases.values():
            if phase_data['total_tasks'] > 0:
                phase_data['task_progress'] = round(phase_data['completed_tasks'] / phase_data['total_tasks'] * 100, 1)
            if phase_data['total_days'] > 0:
                phase_data['time_progress'] = round(phase_data['completed_days'] / phase_data['total_days'] * 100, 1)
        
        return phases
    
    def generate_status_report(self) -> str:
        """生成状态报告"""
        report = []
        report.append("=" * 80)
        report.append("📊 智能物料查重工具 - 项目进度报告")
        report.append("=" * 80)
        report.append(f"📅 生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report.append("")
        
        # 总体进度
        total_tasks = len(self.tasks)
        completed_tasks = sum(1 for task in self.tasks.values() if task.status == TaskStatus.COMPLETED)
        in_progress_tasks = sum(1 for task in self.tasks.values() if task.status == TaskStatus.IN_PROGRESS)
        
        report.append("📈 总体进度:")
        report.append(f"  ✅ 已完成: {completed_tasks}/{total_tasks} ({round(completed_tasks/total_tasks*100, 1)}%)")
        report.append(f"  🔄 进行中: {in_progress_tasks}")
        report.append(f"  📋 待开始: {total_tasks - completed_tasks - in_progress_tasks}")
        report.append("")
        
        # 各阶段进度
        phases = self.get_phase_progress()
        report.append("📊 各阶段进度:")
        for phase, data in phases.items():
            report.append(f"  {phase}:")
            report.append(f"    任务进度: {data['completed_tasks']}/{data['total_tasks']} ({data['task_progress']}%)")
            report.append(f"    时间进度: {data['completed_days']:.1f}/{data['total_days']} 天 ({data['time_progress']}%)")
        report.append("")
        
        # 关键路径状态
        critical_tasks = self.get_critical_path()
        critical_completed = sum(1 for task in critical_tasks if task.status == TaskStatus.COMPLETED)
        report.append("🎯 关键路径状态:")
        report.append(f"  关键任务完成: {critical_completed}/{len(critical_tasks)} ({round(critical_completed/len(critical_tasks)*100, 1)}%)")
        report.append("")
        
        # 可开始的任务
        ready_tasks = self.get_ready_tasks()
        if ready_tasks:
            report.append("🚀 可开始的任务:")
            for task in ready_tasks[:5]:  # 显示前5个
                report.append(f"  {task.id}: {task.title} ({task.priority.value}, {task.estimated_days}天)")
        report.append("")
        
        # 进行中的任务
        in_progress = [task for task in self.tasks.values() if task.status == TaskStatus.IN_PROGRESS]
        if in_progress:
            report.append("🔄 进行中的任务:")
            for task in in_progress:
                report.append(f"  {task.id}: {task.title} ({task.completion_percentage}%)")
        report.append("")
        
        # 风险提醒
        blocked_tasks = [task for task in self.tasks.values() if task.status == TaskStatus.BLOCKED]
        if blocked_tasks:
            report.append("⚠️  阻塞的任务:")
            for task in blocked_tasks:
                report.append(f"  {task.id}: {task.title} - {task.notes}")
        
        return "\n".join(report)
    
    def export_gantt_data(self) -> Dict:
        """导出甘特图数据"""
        gantt_data = {
            'tasks': [],
            'dependencies': []
        }
        
        for task in self.tasks.values():
            task_data = {
                'id': task.id,
                'name': task.title,
                'start': task.start_date or datetime.now().strftime("%Y-%m-%d"),
                'duration': task.estimated_days,
                'progress': task.completion_percentage,
                'type': 'task',
                'assignee': task.assignee,
                'priority': task.priority.value
            }
            gantt_data['tasks'].append(task_data)
            
            # 添加依赖关系
            for dep_id in task.dependencies:
                gantt_data['dependencies'].append({
                    'from': dep_id,
                    'to': task.id,
                    'type': 'finish_to_start'
                })
        
        return gantt_data

def main():
    """主函数 - 命令行界面"""
    tracker = TaskTracker()
    
    while True:
        print("\n" + "="*50)
        print("📋 任务跟踪工具")
        print("="*50)
        print("1. 查看项目状态报告")
        print("2. 更新任务状态")
        print("3. 查看可开始的任务")
        print("4. 查看关键路径")
        print("5. 导出甘特图数据")
        print("0. 退出")
        
        choice = input("\n请选择操作 (0-5): ").strip()
        
        if choice == "0":
            break
        elif choice == "1":
            print(tracker.generate_status_report())
        elif choice == "2":
            task_id = input("请输入任务ID: ").strip()
            if task_id in tracker.tasks:
                print(f"当前任务: {tracker.tasks[task_id].title}")
                print("状态选项: not_started, in_progress, completed, blocked, cancelled")
                status_str = input("请输入新状态: ").strip()
                try:
                    status = TaskStatus(status_str)
                    completion = input("完成百分比 (0-100, 可选): ").strip()
                    completion = int(completion) if completion else None
                    notes = input("备注 (可选): ").strip() or None
                    
                    tracker.update_task_status(task_id, status, completion, notes)
                    print("✅ 任务状态已更新")
                except ValueError as e:
                    print(f"❌ 错误: {e}")
            else:
                print("❌ 任务不存在")
        elif choice == "3":
            ready_tasks = tracker.get_ready_tasks()
            if ready_tasks:
                print("\n🚀 可开始的任务:")
                for task in ready_tasks:
                    print(f"  {task.id}: {task.title} ({task.priority.value}, {task.estimated_days}天)")
            else:
                print("暂无可开始的任务")
        elif choice == "4":
            critical_tasks = tracker.get_critical_path()
            print("\n🎯 关键路径任务:")
            for task in critical_tasks:
                status_icon = "✅" if task.status == TaskStatus.COMPLETED else "🔄" if task.status == TaskStatus.IN_PROGRESS else "⏳"
                print(f"  {status_icon} {task.id}: {task.title} ({task.status.value})")
        elif choice == "5":
            gantt_data = tracker.export_gantt_data()
            with open("gantt_data.json", "w", encoding="utf-8") as f:
                json.dump(gantt_data, f, ensure_ascii=False, indent=2)
            print("✅ 甘特图数据已导出到 gantt_data.json")

if __name__ == "__main__":
    main()
