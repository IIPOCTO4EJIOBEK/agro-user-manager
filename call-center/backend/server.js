const express = require('express');
const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());

// Data storage
let operators = [];
let calls = [];
let callQueue = [];
let analyticsData = [];
let shifts = [];

// Load data from file if exists
const dataFile = path.join(__dirname, 'data.json');
if (fs.existsSync(dataFile)) {
    const data = JSON.parse(fs.readFileSync(dataFile));
    operators = data.operators || [];
    calls = data.calls || [];
    callQueue = data.callQueue || [];
    analyticsData = data.analyticsData || [];
    shifts = data.shifts || [];
}

// Save data to file
function saveData() {
    fs.writeFileSync(dataFile, JSON.stringify({
        operators,
        calls,
        callQueue,
        analyticsData,
        shifts
    }, null, 2));
}

// WebSocket server for real-time updates
const wss = new WebSocket.Server({ port: 8080 });

wss.on('connection', (ws) => {
    console.log('Client connected');
    
    ws.on('message', (message) => {
        try {
            const data = JSON.parse(message);
            handleMessage(ws, data);
        } catch (e) {
            console.error('Error parsing message:', e);
        }
    });

    ws.on('close', () => {
        console.log('Client disconnected');
        // Check if operator was logged in and set to offline
        const operator = operators.find(op => op.ws === ws);
        if (operator) {
            operator.status = 'offline';
            operator.ws = null;
            broadcastUpdate();
            saveData();
        }
    });
});

// Broadcast update to all connected clients
function broadcastUpdate() {
    const update = {
        type: 'update',
        operators: operators.map(op => ({
            id: op.id,
            name: op.name,
            status: op.status,
            currentCalls: op.currentCalls,
            shift: op.shift
        })),
        queue: callQueue,
        calls: calls
    };

    wss.clients.forEach(client => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify(update));
        }
    });
}

// Handle WebSocket messages
function handleMessage(ws, data) {
    switch (data.type) {
        case 'login':
            handleLogin(ws, data);
            break;
        case 'logout':
            handleLogout(ws, data);
            break;
        case 'setStatus':
            handleSetStatus(ws, data);
            break;
        case 'answerCall':
            handleAnswerCall(ws, data);
            break;
        case 'transferCall':
            handleTransferCall(ws, data);
            break;
        case 'holdCall':
            handleHoldCall(ws, data);
            break;
        case 'startBreak':
            handleStartBreak(ws, data);
            break;
        case 'endBreak':
            handleEndBreak(ws, data);
            break;
        case 'incomingCall':
            handleIncomingCall(ws, data);
            break;
        case 'endCall':
            handleEndCall(ws, data);
            break;
        case 'getAnalytics':
            handleGetAnalytics(ws, data);
            break;
        case 'addOperator':
            handleAddOperator(ws, data);
            break;
        case 'updateShift':
            handleUpdateShift(ws, data);
            break;
    }
}

// Login handler
function handleLogin(ws, data) {
    const operator = operators.find(op => op.id === data.operatorId);
    if (operator) {
        operator.ws = ws;
        operator.status = 'free';
        operator.loggedIn = true;
        ws.operatorId = data.operatorId;
        broadcastUpdate();
        saveData();
        ws.send(JSON.stringify({ type: 'loginSuccess', operator }));
    } else {
        ws.send(JSON.stringify({ type: 'loginError', message: 'Operator not found' }));
    }
}

// Logout handler
function handleLogout(ws, data) {
    const operator = operators.find(op => op.id === data.operatorId);
    if (operator) {
        operator.status = 'offline';
        operator.ws = null;
        operator.loggedIn = false;
        broadcastUpdate();
        saveData();
    }
}

// Set status handler
function handleSetStatus(ws, data) {
    const operator = operators.find(op => op.id === data.operatorId);
    if (operator) {
        operator.status = data.status;
        
        // Track break time
        if (data.status === 'break') {
            operator.breakStart = Date.now();
        } else if (data.status === 'free' && operator.breakStart) {
            const breakDuration = Date.now() - operator.breakStart;
            if (!operator.breaks) operator.breaks = [];
            operator.breaks.push({
                start: operator.breakStart,
                end: Date.now(),
                duration: breakDuration
            });
            operator.breakStart = null;
        }
        
        // Track post-call processing
        if (data.status === 'processing') {
            operator.processingStart = Date.now();
        } else if (data.status === 'free' && operator.processingStart) {
            const processingDuration = Date.now() - operator.processingStart;
            if (!operator.processingTimes) operator.processingTimes = [];
            operator.processingTimes.push(processingDuration);
            operator.processingStart = null;
        }
        
        broadcastUpdate();
        saveData();
    }
}

// Answer call handler
function handleAnswerCall(ws, data) {
    const operator = operators.find(op => op.id === data.operatorId);
    const call = calls.find(c => c.id === data.callId);
    
    if (operator && call) {
        // Remove from queue
        callQueue = callQueue.filter(c => c.id !== data.callId);
        
        // Update call
        call.status = 'active';
        call.operatorId = data.operatorId;
        call.answeredAt = Date.now();
        call.waitTime = call.answeredAt - call.createdAt;
        
        // Update operator
        operator.status = 'busy';
        if (!operator.currentCalls) operator.currentCalls = [];
        operator.currentCalls.push(call.id);
        
        // Track analytics
        if (!analyticsData) analyticsData = [];
        analyticsData.push({
            type: 'call_answered',
            callId: call.id,
            operatorId: data.operatorId,
            priority: call.priority,
            timestamp: Date.now(),
            waitTime: call.waitTime
        });
        
        broadcastUpdate();
        saveData();
    }
}

// Transfer call handler
function handleTransferCall(ws, data) {
    const call = calls.find(c => c.id === data.callId);
    if (call) {
        call.transferredTo = data.targetOperatorId || data.targetPhone;
        call.status = 'transferred';
        
        // Track analytics
        analyticsData.push({
            type: 'call_transferred',
            callId: call.id,
            fromOperatorId: data.fromOperatorId,
            toOperatorId: data.targetOperatorId,
            toPhone: data.targetPhone,
            timestamp: Date.now()
        });
        
        broadcastUpdate();
        saveData();
    }
}

// Hold call handler
function handleHoldCall(ws, data) {
    const call = calls.find(c => c.id === data.callId);
    if (call) {
        call.onHold = !call.onHold;
        broadcastUpdate();
        saveData();
    }
}

// Start break handler
function handleStartBreak(ws, data) {
    handleSetStatus(ws, { operatorId: data.operatorId, status: 'break' });
}

// End break handler
function handleEndBreak(ws, data) {
    handleSetStatus(ws, { operatorId: data.operatorId, status: 'free' });
}

// Incoming call handler
function handleIncomingCall(ws, data) {
    const call = {
        id: uuidv4(),
        callerNumber: data.callerNumber,
        priority: data.priority || 3, // 1=VIP, 2=Important, 3=Normal
        status: 'queued',
        createdAt: Date.now(),
        region: data.region,
        onHold: false
    };
    
    calls.push(call);
    
    // Add to queue with priority
    const queuePosition = callQueue.findIndex(c => c.priority > call.priority);
    if (queuePosition === -1) {
        callQueue.push(call);
    } else {
        callQueue.splice(queuePosition, 0, call);
    }
    
    // Notify all operators about VIP call
    if (call.priority === 1) {
        broadcastUpdate();
        // Escalate to manager after timeout (simulated)
        setTimeout(() => {
            const stillQueued = callQueue.find(c => c.id === call.id);
            if (stillQueued && stillQueued.priority === 1) {
                // Find manager
                const manager = operators.find(op => op.isManager && op.status === 'free');
                if (manager) {
                    callQueue = callQueue.filter(c => c.id !== call.id);
                    call.status = 'escalated';
                    call.operatorId = manager.id;
                    broadcastUpdate();
                    
                    analyticsData.push({
                        type: 'vip_escalated',
                        callId: call.id,
                        managerId: manager.id,
                        timestamp: Date.now()
                    });
                    saveData();
                }
            }
        }, data.escalationTimeout || 30000); // 30 seconds default
    } else {
        broadcastUpdate();
    }
    
    saveData();
}

// End call handler
function handleEndCall(ws, data) {
    const call = calls.find(c => c.id === data.callId);
    const operator = operators.find(op => op.id === data.operatorId);
    
    if (call && operator) {
        call.status = 'completed';
        call.endedAt = Date.now();
        call.duration = call.endedAt - call.answeredAt;
        
        // Remove from operator's current calls
        if (operator.currentCalls) {
            operator.currentCalls = operator.currentCalls.filter(id => id !== call.id);
        }
        
        // Set operator to processing status
        operator.status = 'processing';
        operator.processingStart = Date.now();
        
        // Track analytics
        analyticsData.push({
            type: 'call_completed',
            callId: call.id,
            operatorId: data.operatorId,
            duration: call.duration,
            priority: call.priority,
            timestamp: Date.now()
        });
        
        broadcastUpdate();
        saveData();
    }
}

// Get analytics handler
function handleGetAnalytics(ws, data) {
    const { period, operatorId } = data;
    const now = Date.now();
    let startTime;
    
    // Calculate start time based on period
    switch (period) {
        case 'hour':
            startTime = now - 3600000;
            break;
        case 'day':
            startTime = now - 86400000;
            break;
        case 'week':
            startTime = now - 604800000;
            break;
        case 'month':
            startTime = now - 2592000000;
            break;
        default:
            startTime = data.startTime || 0;
    }
    
    const filteredData = analyticsData.filter(d => d.timestamp >= startTime);
    
    let result = {
        totalCalls: 0,
        answeredCalls: 0,
        missedCalls: 0,
        transferredCalls: 0,
        vipEscalated: 0,
        avgWaitTime: 0,
        avgCallDuration: 0,
        totalBreakTime: 0,
        avgProcessingTime: 0
    };
    
    if (operatorId) {
        // Operator-specific analytics
        const op = operators.find(o => o.id === operatorId);
        if (op) {
            const opData = filteredData.filter(d => d.operatorId === operatorId);
            
            result.totalCalls = opData.filter(d => d.type === 'call_answered').length;
            result.answeredCalls = result.totalCalls;
            result.transferredCalls = opData.filter(d => d.type === 'call_transferred' && d.fromOperatorId === operatorId).length;
            result.vipEscalated = opData.filter(d => d.type === 'vip_escalated' && d.managerId === operatorId).length;
            
            const waitTimes = opData.filter(d => d.type === 'call_answered').map(d => d.waitTime);
            result.avgWaitTime = waitTimes.length ? waitTimes.reduce((a, b) => a + b, 0) / waitTimes.length : 0;
            
            const durations = opData.filter(d => d.type === 'call_completed').map(d => d.duration);
            result.avgCallDuration = durations.length ? durations.reduce((a, b) => a + b, 0) / durations.length : 0;
            
            if (op.breaks) {
                const recentBreaks = op.breaks.filter(b => b.start >= startTime);
                result.totalBreakTime = recentBreaks.reduce((a, b) => a + b.duration, 0);
            }
            
            if (op.processingTimes) {
                const recentProcessing = op.processingTimes.filter(t => 
                    op.processingStart && (op.processingStart - t) >= startTime
                );
                result.avgProcessingTime = recentProcessing.length ? 
                    recentProcessing.reduce((a, b) => a + b, 0) / recentProcessing.length : 0;
            }
        }
    } else {
        // Overall analytics
        result.totalCalls = filteredData.filter(d => d.type === 'call_answered').length;
        result.answeredCalls = result.totalCalls;
        result.transferredCalls = filteredData.filter(d => d.type === 'call_transferred').length;
        result.vipEscalated = filteredData.filter(d => d.type === 'vip_escalated').length;
        
        const waitTimes = filteredData.filter(d => d.type === 'call_answered').map(d => d.waitTime);
        result.avgWaitTime = waitTimes.length ? waitTimes.reduce((a, b) => a + b, 0) / waitTimes.length : 0;
        
        const durations = filteredData.filter(d => d.type === 'call_completed').map(d => d.duration);
        result.avgCallDuration = durations.length ? durations.reduce((a, b) => a + b, 0) / durations.length : 0;
    }
    
    ws.send(JSON.stringify({ type: 'analytics', data: result, period }));
}

// Add operator handler
function handleAddOperator(ws, data) {
    const operator = {
        id: data.id || uuidv4(),
        name: data.name,
        status: 'offline',
        loggedIn: false,
        isManager: data.isManager || false,
        currentCalls: [],
        shift: data.shift || null,
        breaks: [],
        processingTimes: []
    };
    
    operators.push(operator);
    broadcastUpdate();
    saveData();
    ws.send(JSON.stringify({ type: 'operatorAdded', operator }));
}

// Update shift handler
function handleUpdateShift(ws, data) {
    const operator = operators.find(op => op.id === data.operatorId);
    if (operator) {
        operator.shift = data.shift;
        shifts.push({
            operatorId: data.operatorId,
            shift: data.shift,
            timestamp: Date.now()
        });
        broadcastUpdate();
        saveData();
    }
}

// REST API endpoints
app.get('/api/operators', (req, res) => {
    res.json(operators.map(op => ({
        id: op.id,
        name: op.name,
        status: op.status,
        isManager: op.isManager,
        shift: op.shift
    })));
});

app.post('/api/operators', (req, res) => {
    const operator = {
        id: uuidv4(),
        name: req.body.name,
        status: 'offline',
        loggedIn: false,
        isManager: req.body.isManager || false,
        currentCalls: [],
        shift: req.body.shift || null
    };
    operators.push(operator);
    saveData();
    res.json(operator);
});

app.get('/api/calls', (req, res) => {
    res.json(calls);
});

app.get('/api/queue', (req, res) => {
    res.json(callQueue);
});

app.get('/api/analytics', (req, res) => {
    const { period, operatorId } = req.query;
    const now = Date.now();
    let startTime;
    
    switch (period) {
        case 'hour':
            startTime = now - 3600000;
            break;
        case 'day':
            startTime = now - 86400000;
            break;
        case 'week':
            startTime = now - 604800000;
            break;
        case 'month':
            startTime = now - 2592000000;
            break;
        default:
            startTime = 0;
    }
    
    const filteredData = analyticsData.filter(d => d.timestamp >= startTime);
    
    let result = {
        totalCalls: filteredData.filter(d => d.type === 'call_answered').length,
        answeredCalls: filteredData.filter(d => d.type === 'call_answered').length,
        transferredCalls: filteredData.filter(d => d.type === 'call_transferred').length,
        vipEscalated: filteredData.filter(d => d.type === 'vip_escalated').length,
        byOperator: {}
    };
    
    // Group by operator
    operators.forEach(op => {
        const opData = filteredData.filter(d => d.operatorId === op.id);
        result.byOperator[op.id] = {
            name: op.name,
            totalCalls: opData.filter(d => d.type === 'call_answered').length,
            avgWaitTime: 0,
            avgCallDuration: 0
        };
        
        const waitTimes = opData.filter(d => d.type === 'call_answered').map(d => d.waitTime);
        if (waitTimes.length) {
            result.byOperator[op.id].avgWaitTime = waitTimes.reduce((a, b) => a + b, 0) / waitTimes.length;
        }
        
        const durations = opData.filter(d => d.type === 'call_completed').map(d => d.duration);
        if (durations.length) {
            result.byOperator[op.id].avgCallDuration = durations.reduce((a, b) => a + b, 0) / durations.length;
        }
    });
    
    res.json(result);
});

app.get('/api/analytics/export', (req, res) => {
    const { period, format } = req.query;
    // Export logic for CSV/Excel
    let csv = 'Timestamp,Type,CallID,OperatorID,Duration,Priority\n';
    
    analyticsData.forEach(record => {
        csv += `${record.timestamp},${record.type},${record.callId || ''},${record.operatorId || ''},${record.duration || 0},${record.priority || ''}\n`;
    });
    
    if (format === 'csv') {
        res.setHeader('Content-Type', 'text/csv');
        res.setHeader('Content-Disposition', 'attachment; filename=analytics.csv');
        res.send(csv);
    } else {
        res.json(analyticsData);
    }
});

app.post('/api/calls/incoming', (req, res) => {
    const call = {
        id: uuidv4(),
        callerNumber: req.body.callerNumber,
        priority: req.body.priority || 3,
        status: 'queued',
        createdAt: Date.now(),
        region: req.body.region
    };
    
    calls.push(call);
    callQueue.push(call);
    
    // Simulate WebSocket broadcast
    broadcastUpdate();
    saveData();
    
    res.json(call);
});

// Initialize with some demo operators if empty
if (operators.length === 0) {
    operators = [
        { id: 'op1', name: 'Оператор 1', status: 'offline', loggedIn: false, isManager: false, currentCalls: [], shift: null, breaks: [], processingTimes: [] },
        { id: 'op2', name: 'Оператор 2', status: 'offline', loggedIn: false, isManager: false, currentCalls: [], shift: null, breaks: [], processingTimes: [] },
        { id: 'op3', name: 'Оператор 3', status: 'offline', loggedIn: false, isManager: false, currentCalls: [], shift: null, breaks: [], processingTimes: [] },
        { id: 'op4', name: 'Оператор 4', status: 'offline', loggedIn: false, isManager: false, currentCalls: [], shift: null, breaks: [], processingTimes: [] },
        { id: 'op5', name: 'Оператор 5', status: 'offline', loggedIn: false, isManager: false, currentCalls: [], shift: null, breaks: [], processingTimes: [] },
        { id: 'op6', name: 'Оператор 6', status: 'offline', loggedIn: false, isManager: false, currentCalls: [], shift: null, breaks: [], processingTimes: [] },
        { id: 'op7', name: 'Менеджер', status: 'offline', loggedIn: false, isManager: true, currentCalls: [], shift: null, breaks: [], processingTimes: [] }
    ];
    saveData();
}

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`WebSocket server running on port 8080`);
});
