import from uuid { uuid4 }
import from byllm.lib { Model }
cl import "./styles.css";

glob llm = Model(model_name="gemini/gemini-2.5-flash");

enum Category { HEALTH, WORK, PERSONAL, OTHER, SHOPPING }

def categorize(title: str) -> Category by llm();

"""Map category to priority (lower number = higher priority)."""
def category_priority(category: str) -> int {
    return {
        "health": 1,
        "work": 2,
        "personal": 3,
        "other": 4,
        "shopping": 5
    }.get(category, 5);
}

node Todo {
    has id: str,
        title: str,
        done: bool = False,
        category: str = "other",
        priority: int = 5;
}

"""Add a todo with AI categorization."""
def:pub add_todo(title: str) -> dict {
    category = str(categorize(title)).split(".")[-1].lower();
    priority = category_priority(category);
    todo = root ++> Todo(
        id=str(uuid4()),
        title=title,
        category=category,
        priority=priority
    );
    return {
        "id": todo[0].id, "title": todo[0].title,
        "done": todo[0].done, "category": todo[0].category,
        "priority": todo[0].priority
    };
}

"""Get all todos."""
def:pub get_todos -> list {
    return [
        {
            "id": t.id,
            "title": t.title,
            "done": t.done,
            "category": t.category,
            "priority": category_priority(t.category)
        }
        for t in [root-->](?:Todo)
    ];
}

"""Toggle a todo's done status."""
def:pub toggle_todo(id: str) -> dict {
    for todo in [root-->](?:Todo) {
        if todo.id == id {
            todo.done = not todo.done;
            return {
                "id": todo.id, "title": todo.title,
                "done": todo.done, "category": todo.category,
                "priority": category_priority(todo.category)
            };
        }
    }
    return {};
}

"""Delete a todo."""
def:pub delete_todo(id: str) -> dict {
    for todo in [root-->](?:Todo) {
        if todo.id == id {
            del todo;
            return {"deleted": id};
        }
    }
    return {};
}

cl def:pub app -> object {
    has items: list = [],
        text: str = "",
        health_rank: int = 1,
        work_rank: int = 2,
        personal_rank: int = 3,
        other_rank: int = 4,
        shopping_rank: int = 5;

    def rank_for_category(category: str) -> int {
        if category == "health" { return health_rank; }
        if category == "work" { return work_rank; }
        if category == "personal" { return personal_rank; }
        if category == "shopping" { return shopping_rank; }
        return other_rank;
    }

    def category_at_rank(rank: int) -> str {
        if health_rank == rank { return "health"; }
        if work_rank == rank { return "work"; }
        if personal_rank == rank { return "personal"; }
        if shopping_rank == rank { return "shopping"; }
        return "other";
    }

    def set_rank(category: str, rank: int) -> None {
        if category == "health" { health_rank = rank; return; }
        if category == "work" { work_rank = rank; return; }
        if category == "personal" { personal_rank = rank; return; }
        if category == "shopping" { shopping_rank = rank; return; }
        other_rank = rank;
    }

    def sort_items(todos: list) -> list {
        ordered = [];
        for p in [1, 2, 3, 4, 5] {
            ordered = ordered.concat(
                todos.filter(
                    lambda t: any -> bool { return rank_for_category(t.category) == p; }
                )
            );
        }
        return ordered;
    }

    def move_up(category: str) -> None {
        current_rank = rank_for_category(category);
        if current_rank <= 1 { return; }
        category_above = category_at_rank(current_rank - 1);
        set_rank(category, current_rank - 1);
        set_rank(category_above, current_rank);
    }

    def move_down(category: str) -> None {
        current_rank = rank_for_category(category);
        if current_rank >= 5 { return; }
        category_below = category_at_rank(current_rank + 1);
        set_rank(category, current_rank + 1);
        set_rank(category_below, current_rank);
    }

    async can with entry {
        items = await get_todos();
    }

    async def add -> None {
        if text.trim() {
            todo = await add_todo(text.trim());
            items = items.concat([todo]);
            text = "";
        }
    }

    async def toggle(id: str) -> None {
        await toggle_todo(id);
        items = items.map(
            lambda t: any -> any {
                return {
                    "id": t.id, "title": t.title,
                    "done": not t.done, "category": t.category,
                    "priority": rank_for_category(t.category)
                }
                if t.id == id else t;
            }
        );
    }


    async def remove(id: str) -> None {
        await delete_todo(id);
        items = items.filter(lambda t: any -> bool { return t.id != id; });
    }

    sorted_items = sort_items(items);

    remaining = 0;
    for t in sorted_items {
        if not t.done {
            remaining = remaining + 1;
        }
    }

    return
        <div class="container">
            <h1>Todo App</h1>
            <div class="priority-panel">
                <div class="priority-title">Category Priority</div>
                {[
                    <div key={cat} class="priority-row">
                        <span class="category">{cat}</span>
                        <span class="priority-rank">P{rank_for_category(cat)}</span>
                        <button
                            class="btn-priority"
                            disabled={rank_for_category(cat) == 1}
                            onClick={lambda -> None { move_up(cat); }}
                        >
                            ↑
                        </button>
                        <button
                            class="btn-priority"
                            disabled={rank_for_category(cat) == 5}
                            onClick={lambda -> None { move_down(cat); }}
                        >
                            ↓
                        </button>
                    </div> for cat in ["health", "work", "personal", "other", "shopping"]
                ]}
            </div>
            <div class="input-row">
                <input
                    class="input"
                    value={text}
                    onChange={lambda e: any -> None { text = e.target.value; }}
                    onKeyPress={lambda e: any -> None {
                        if e.key == "Enter" { add(); }
                    }}
                    placeholder="What needs to be done?"
                />
                <button class="btn-add" onClick={add}>Add</button>
            </div>
            {[
                <div key={t.id} class="todo-item">
                    <input
                        type="checkbox"
                        checked={t.done}
                        onChange={lambda -> None { toggle(t.id); }}
                    />
                    <span class={"todo-title " + ("todo-done" if t.done else "")}>
                        {t.title}
                    </span>
                    <span class="category">{t.category}</span>
                    <span class="category">P{rank_for_category(t.category)}</span>
                    <button
                        class="btn-delete"
                        onClick={lambda -> None { remove(t.id); }}
                    >
                        X
                    </button>
                </div> for t in sorted_items
            ]}
            <div class="count">{remaining} items remaining</div>
        </div>;
}
