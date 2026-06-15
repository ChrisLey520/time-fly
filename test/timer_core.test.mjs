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
    sessions: [],
    tasks: []
  };
}

function createTimerCore(storage, nowRef) {
  const idle = () => ({
    id: '',
    mode: 'focus',
    status: 'idle',
    durationSeconds: 0,
    accumulatedPausedMs: 0
  });

  return {
    startFocus(durationSeconds = 60) {
      const now = nowRef.now;
      storage.timerState = {
        id: `timer_${now}`,
        mode: 'focus',
        status: 'running',
        taskId: 'task_1',
        taskTitle: '自由专注',
        startedAt: now,
        expectedEndAt: now + durationSeconds * 1000,
        durationSeconds,
        accumulatedPausedMs: 0
      };
      return storage.timerState;
    },

    pause() {
      const state = storage.timerState;
      if (state.status !== 'running') return state;
      state.status = 'paused';
      state.pausedAt = nowRef.now;
      return state;
    },

    resume() {
      const state = storage.timerState;
      if (state.status !== 'paused' || !state.pausedAt || !state.expectedEndAt) return state;
      const pausedMs = nowRef.now - state.pausedAt;
      state.status = 'running';
      state.expectedEndAt += pausedMs;
      state.accumulatedPausedMs += pausedMs;
      state.pausedAt = undefined;
      return state;
    },

    complete() {
      const state = storage.timerState;
      if (state.status === 'idle' || !state.startedAt || !state.expectedEndAt) return null;
      const session = {
        id: `session_${nowRef.now}`,
        taskTitle: state.taskTitle,
        plannedDurationSeconds: state.durationSeconds,
        actualDurationSeconds: state.durationSeconds,
        startedAt: state.startedAt,
        endedAt: state.expectedEndAt,
        status: 'completed'
      };
      storage.sessions.unshift(session);
      const task = storage.tasks.find((item) => item.id === state.taskId);
      if (task) {
        task.completedFocusCount += 1;
      }
      storage.timerState = {
        id: '',
        mode: 'break',
        status: 'idle',
        taskTitle: '歇息',
        durationSeconds: 300,
        accumulatedPausedMs: 0
      };
      return session;
    },

    abandon() {
      const state = storage.timerState;
      if (state.status === 'idle' || !state.startedAt) return null;
      const pausedExtraMs = state.status === 'paused' && state.pausedAt ? nowRef.now - state.pausedAt : 0;
      const actualDurationSeconds = Math.max(
        0,
        Math.floor((nowRef.now - state.startedAt - state.accumulatedPausedMs - pausedExtraMs) / 1000)
      );
      const session = {
        id: `session_${nowRef.now}`,
        taskTitle: state.taskTitle,
        plannedDurationSeconds: state.durationSeconds,
        actualDurationSeconds,
        startedAt: state.startedAt,
        endedAt: nowRef.now,
        status: 'abandoned'
      };
      storage.sessions.unshift(session);
      storage.timerState = idle();
      return session;
    },

    restore() {
      const state = storage.timerState;
      if (state.status === 'idle') return state;
      if (state.status === 'running' && state.expectedEndAt <= nowRef.now) {
        if (state.mode === 'break') {
          storage.timerState = idle();
        } else {
          this.complete();
        }
        return storage.timerState;
      }
      return state;
    },

    getRemainingSeconds() {
      const state = storage.timerState;
      if (state.status === 'idle') return state.mode === 'break' ? state.durationSeconds : 0;
      if (state.status === 'paused' && state.pausedAt && state.expectedEndAt) {
        return Math.max(0, Math.ceil((state.expectedEndAt - state.pausedAt) / 1000));
      }
      return Math.max(0, Math.ceil((state.expectedEndAt - nowRef.now) / 1000));
    }
  };
}

{
  const storage = createMemoryStorage();
  storage.tasks.push({
    id: 'task_1',
    title: '自由专注',
    estimatedFocusCount: 2,
    completedFocusCount: 0,
    status: 'active'
  });
  const nowRef = { now: 1_000_000 };
  const timer = createTimerCore(storage, nowRef);

  timer.startFocus(60);
  assert.equal(timer.getRemainingSeconds(), 60);

  nowRef.now += 10_000;
  assert.equal(timer.getRemainingSeconds(), 50);

  timer.pause();
  nowRef.now += 20_000;
  assert.equal(timer.getRemainingSeconds(), 50);

  timer.resume();
  assert.equal(timer.getRemainingSeconds(), 50);
  assert.equal(storage.timerState.accumulatedPausedMs, 20_000);

  nowRef.now += 50_000;
  timer.restore();
  assert.equal(storage.timerState.status, 'idle');
  assert.equal(storage.timerState.mode, 'break');
  assert.equal(timer.getRemainingSeconds(), 300);
  assert.equal(storage.sessions.length, 1);
  assert.equal(storage.sessions[0].status, 'completed');
  assert.equal(storage.sessions[0].actualDurationSeconds, 60);
  assert.equal(storage.tasks[0].completedFocusCount, 1);
}

{
  const storage = createMemoryStorage();
  storage.tasks.push({
    id: 'task_1',
    title: '自由专注',
    estimatedFocusCount: 2,
    completedFocusCount: 0,
    status: 'active'
  });
  const nowRef = { now: 5_000_000 };
  const timer = createTimerCore(storage, nowRef);

  timer.startFocus(60);
  nowRef.now += 12_200;
  const session = timer.abandon();

  assert.equal(session.status, 'abandoned');
  assert.equal(session.actualDurationSeconds, 12);
  assert.equal(storage.timerState.status, 'idle');
  assert.equal(storage.tasks[0].completedFocusCount, 0);
}

console.log('timer core tests passed');
