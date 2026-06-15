import assert from 'node:assert/strict';

function createMemoryStorage() {
  return {
    timerState: {
      id: '',
      mode: 'focus',
      status: 'idle',
      durationSeconds: 0,
      accumulatedPausedMs: 0
    },
    tasks: [
      {
        id: 'task_1',
        title: '写方案',
        estimatedFocusCount: 2,
        completedFocusCount: 0,
        status: 'active'
      },
      {
        id: 'task_2',
        title: '整理资料',
        estimatedFocusCount: 1,
        completedFocusCount: 0,
        status: 'active'
      }
    ]
  };
}

function createTaskCore(storage) {
  function isTaskLockedByTimer(taskId) {
    const state = storage.timerState;
    return state.mode === 'focus' && state.status !== 'idle' && state.taskId === taskId;
  }

  return {
    update(taskId, title, estimatedFocusCount) {
      if (isTaskLockedByTimer(taskId)) return null;
      const task = storage.tasks.find((item) => item.id === taskId);
      if (!task) return null;

      task.title = title.trim() || task.title;
      task.estimatedFocusCount = Math.max(1, estimatedFocusCount);
      return task;
    },

    delete(taskId) {
      if (isTaskLockedByTimer(taskId)) return false;
      storage.tasks = storage.tasks.filter((task) => task.id !== taskId);
      return true;
    },

    markCompleted(taskId) {
      if (isTaskLockedByTimer(taskId)) return null;
      const task = storage.tasks.find((item) => item.id === taskId);
      if (!task) return null;

      task.status = 'completed';
      return task;
    },

    archive(taskId) {
      if (isTaskLockedByTimer(taskId)) return null;
      const task = storage.tasks.find((item) => item.id === taskId);
      if (!task) return null;

      task.status = 'archived';
      return task;
    },

    incrementCompletedFocusCount(taskId) {
      const task = storage.tasks.find((item) => item.id === taskId);
      if (!task) return null;

      task.completedFocusCount += 1;
      if (task.completedFocusCount >= task.estimatedFocusCount) {
        task.status = 'completed';
      }
      return task;
    }
  };
}

{
  const storage = createMemoryStorage();
  const taskCore = createTaskCore(storage);
  storage.timerState = {
    id: 'timer_1',
    mode: 'focus',
    status: 'running',
    taskId: 'task_1',
    taskTitle: '写方案',
    durationSeconds: 1500,
    accumulatedPausedMs: 0
  };

  assert.equal(taskCore.update('task_1', '新标题', 4), null);
  assert.equal(taskCore.markCompleted('task_1'), null);
  assert.equal(taskCore.archive('task_1'), null);
  assert.equal(taskCore.delete('task_1'), false);
  assert.equal(storage.tasks.length, 2);
  assert.equal(storage.tasks[0].title, '写方案');
  assert.equal(storage.tasks[0].status, 'active');

  assert.equal(taskCore.delete('task_2'), true);
  assert.equal(storage.tasks.length, 1);
}

{
  const storage = createMemoryStorage();
  const taskCore = createTaskCore(storage);
  storage.timerState = {
    id: 'timer_1',
    mode: 'focus',
    status: 'running',
    taskId: 'task_1',
    taskTitle: '写方案',
    durationSeconds: 1500,
    accumulatedPausedMs: 0
  };

  const task = taskCore.incrementCompletedFocusCount('task_1');
  assert.equal(task.completedFocusCount, 1);
  assert.equal(task.status, 'active');

  const completedTask = taskCore.incrementCompletedFocusCount('task_1');
  assert.equal(completedTask.completedFocusCount, 2);
  assert.equal(completedTask.status, 'completed');
}

console.log('task core tests passed');
