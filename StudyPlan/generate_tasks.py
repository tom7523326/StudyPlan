import json
from datetime import datetime, timedelta
import uuid

template_tasks = [
    {"name": "同步练字帖（三张）", "category": "语文", "expectedMinutes": 20},
    {"name": "阅读人文天天练（一篇）", "category": "语文", "expectedMinutes": 10},
    {"name": "同步作文（三天写两篇）", "category": "语文", "expectedMinutes": 30},
    {"name": "每次读书40分钟，抄好句子", "category": "语文", "expectedMinutes": 40},
    {"name": "数感小超市（每日一篇）", "category": "数学", "expectedMinutes": 10},
    {"name": "数学探物（每日一主题）", "category": "数学", "expectedMinutes": 20},
    {"name": "斑马1天2集", "category": "英语", "expectedMinutes": 30},
    {"name": "配音", "category": "英语", "expectedMinutes": 10},
    {"name": "自我介绍3遍", "category": "英语", "expectedMinutes": 10}
]

start_date = datetime(2025, 7, 12)
end_date = datetime(2025, 8, 10)
all_tasks = []

current_date = start_date
while current_date <= end_date:
    for t in template_tasks:
        all_tasks.append({
            "id": str(uuid.uuid4()),
            "name": t["name"],
            "category": t["category"],
            "expectedMinutes": t["expectedMinutes"],
            "actualMinutes": 0,
            "date": current_date.strftime("%Y-%m-%dT00:00:00Z"),
            "status": "未开始"
        })
    current_date += timedelta(days=1)

with open("tasks.json", "w", encoding="utf-8") as f:
    json.dump(all_tasks, f, ensure_ascii=False, indent=2) 
