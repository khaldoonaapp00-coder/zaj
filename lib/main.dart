<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <title>معركة بيت عليجان</title>
    <style>
        * {
            user-select: none;
            -webkit-user-select: none;
            box-sizing: border-box;
        }
        body {
            margin: 0;
            padding: 0;
            background-color: #111;
            color: #fff;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            overflow: hidden;
        }
        #game-container {
            position: relative;
            width: 100vw;
            height: 100vh;
            background: #2b2b2b;
            display: flex;
            flex-direction: column;
            align-items: center;
        }
        #hud {
            position: absolute;
            top: 10px;
            width: 95%;
            display: flex;
            justify-content: space-between;
            z-index: 10;
            background: rgba(0,0,0,0.6);
            padding: 8px 15px;
            border-radius: 8px;
        }
        .team-hud {
            font-size: 14px;
            line-height: 1.4;
        }
        .team1-text { color: #4dabf7; }
        .team2-text { color: #ff6b6b; }
        
        canvas {
            background: #3e3a35; /* أرضية بيت عليجان */
            box-shadow: 0 0 20px rgba(0,0,0,0.8);
        }

        /* أزرار تحكم ببجي */
        .controls-layer {
            position: absolute;
            bottom: 15px;
            width: 100%;
            height: 180px;
            pointer-events: none;
            display: flex;
            justify-content: space-between;
            padding: 0 20px;
        }
        .dpad, .action-buttons {
            pointer-events: auto;
        }
        .dpad {
            display: grid;
            grid-template-columns: repeat(3, 50px);
            grid-template-rows: repeat(3, 50px);
            gap: 5px;
        }
        .btn-ctrl {
            background: rgba(255, 255, 255, 0.25);
            border: 2px solid rgba(255, 255, 255, 0.4);
            border-radius: 10px;
            color: white;
            font-weight: bold;
            font-size: 18px;
            display: flex;
            align-items: center;
            justify-content: center;
            touch-action: manipulation;
        }
        .btn-ctrl:active {
            background: rgba(255, 255, 255, 0.5);
        }
        .action-buttons {
            display: flex;
            gap: 15px;
            align-items: flex-end;
            margin-bottom: 10px;
        }
        .btn-action {
            width: 70px;
            height: 70px;
            border-radius: 50%;
            font-size: 14px;
            font-weight: bold;
        }
        .btn-shoot { background: rgba(231, 76, 60, 0.7); border: 2px solid #e74c3c; }
        .btn-switch { background: rgba(241, 196, 15, 0.7); border: 2px solid #f1c40f; color: #000; }
        
        #kill-feed {
            position: absolute;
            top: 60px;
            right: 20px;
            background: rgba(0, 0, 0, 0.5);
            color: #f39c12;
            padding: 5px 10px;
            border-radius: 5px;
            font-size: 13px;
        }
    </style>
</head>
<body>

<div id="game-container">
    <div id="hud">
        <div class="team-hud team1-text" id="t1-stats">فريق عبد الحسين</div>
        <div class="team-hud team2-text" id="t2-stats">فريق ثامر</div>
    </div>
    <div id="kill-feed">جاهز للمعركة!</div>
    <canvas id="gameCanvas"></canvas>

    <!-- أزرار تحكم شاشة اللمس (نمط ببجي) -->
    <div class="controls-layer">
        <div class="dpad">
            <div></div>
            <div class="btn-ctrl" id="btn-up">▲</div>
            <div></div>
            <div class="btn-ctrl" id="btn-left">◄</div>
            <div></div>
            <div class="btn-ctrl" id="btn-right">►</div>
            <div></div>
            <div class="btn-ctrl" id="btn-down">▼</div>
            <div></div>
        </div>
        <div class="action-buttons">
            <button class="btn-ctrl btn-action btn-switch" id="btn-switch">سلاح</button>
            <button class="btn-ctrl btn-action btn-shoot" id="btn-shoot">إطلاق</button>
        </div>
    </div>
</div>

<script>
const canvas = document.getElementById('gameCanvas');
const ctx = canvas.getContext('2d');

// ضبط أبعاد اللعبة
canvas.width = Math.min(window.innerWidth, 800);
canvas.height = window.innerHeight - 200;

// نظام الصوت المخصص بالتأثيرات العراقية
const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
const voicePhrases = [
    "يا بوية اكلتها!",
    "طاح حظك يا ثامر!",
    "ولك وين رايح بالتوثية؟",
    "عوف المسدس وتعال وجه بوجه!",
    "هاي وحدة لعيون عبد الحسين!"
];

function playIraqiVoiceSound() {
    if ('speechSynthesis' in window) {
        const text = voicePhrases[Math.floor(Math.random() * voicePhrases.length)];
        const msg = new SpeechSynthesisUtterance(text);
        msg.lang = 'ar-IQ'; // لهجة عراقية إن دعمتها المنصة أو عربية عامة
        msg.rate = 1.1;
        window.speechSynthesis.speak(msg);
    }
}

function playGunSound() {
    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();
    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(300, audioCtx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.15);
    gain.gain.setValueAtTime(0.3, audioCtx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.15);
    osc.connect(gain);
    gain.connect(audioCtx.destination);
    osc.start();
    osc.stop(audioCtx.currentTime + 0.15);
}

// تعريف الشخصيات والأسلحة
class Character {
    constructor(name, team, x, y, color) {
        this.name = name;
        this.team = team;
        this.x = x;
        this.y = y;
        this.color = color;
        this.hp = 100;
        this.weapon = 'مسدس'; // أو 'توثية'
        this.alive = true;
        this.radius = 18;
        this.speed = 3;
    }

    draw() {
        if (!this.alive) return;
        ctx.beginPath();
        ctx.arc(this.x, this.y, this.radius, 0, Math.PI * 2);
        ctx.fillStyle = this.color;
        ctx.fill();
        ctx.lineWidth = 3;
        ctx.strokeStyle = '#fff';
        ctx.stroke();

        // رسم السلاح
        ctx.beginPath();
        ctx.moveTo(this.x, this.y);
        ctx.lineTo(this.x + (this.weapon === 'مسدس' ? 25 : 35), this.y);
        ctx.strokeStyle = this.weapon === 'مسدس' ? '#f1c40f' : '#8e44ad';
        ctx.lineWidth = this.weapon === 'مسدس' ? 4 : 7;
        ctx.stroke();

        // اسم الشخصية وشريط الصحة
        ctx.fillStyle = '#fff';
        ctx.font = '12px Arial';
        ctx.textAlign = 'center';
        ctx.fillText(this.name, this.x, this.y - 25);

        ctx.fillStyle = 'red';
        ctx.fillRect(this.x - 15, this.y - 22, 30, 4);
        ctx.fillStyle = 'green';
        ctx.fillRect(this.x - 15, this.y - 22, (this.hp / 100) * 30, 4);
    }
}

// إنشاء الفرق
const team1 = [
    new Character('عبد الحسين', 1, 100, canvas.height / 2 - 50, '#3498db'),
    new Character('أمير', 1, 100, canvas.height / 2, '#3498db'),
    new Character('علاء', 1, 100, canvas.height / 2 + 50, '#3498db')
];

const team2 = [
    new Character('ثامر', 2, canvas.width - 100, canvas.height / 2 - 50, '#e74c3c'),
    new Character('رعد', 2, canvas.width - 100, canvas.height / 2, '#e74c3c'),
    new Character('أبو حنان', 2, canvas.width - 100, canvas.height / 2 + 50, '#e74c3c')
];

let player = team1[0]; // التحكم بالشخصية الرئيسية
let bullets = [];

// المدخلات
const keys = {};

function handleTouch(id, state) { keys[id] = state; }

// ربط أزرار الشاشة
const bindBtn = (id, key) => {
    const el = document.getElementById(id);
    el.addEventListener('touchstart', (e) => { e.preventDefault(); keys[key] = true; });
    el.addEventListener('touchend', (e) => { e.preventDefault(); keys[key] = false; });
    el.addEventListener('mousedown', () => keys[key] = true);
    el.addEventListener('mouseup', () => keys[key] = false);
};

bindBtn('btn-up', 'ArrowUp');
bindBtn('btn-down', 'ArrowDown');
bindBtn('btn-left', 'ArrowLeft');
bindBtn('btn-right', 'ArrowRight');

document.getElementById('btn-switch').onclick = () => {
    player.weapon = player.weapon === 'مسدس' ? 'توثية' : 'مسدس';
};

document.getElementById('btn-shoot').onclick = () => {
    shoot(player);
};

function shoot(char) {
    if (!char.alive) return;
    if (char.weapon === 'مسدس') {
        playGunSound();
        bullets.push({
            x: char.x + 20,
            y: char.y,
            vx: char.team === 1 ? 8 : -8,
            team: char.team
        });
    } else {
        // هجوم بالتوثية (مدى قريب)
        const targets = char.team === 1 ? team2 : team1;
        targets.forEach(target => {
            if (target.alive && Math.hypot(target.x - char.x, target.y - char.y) < 55) {
                target.hp -= 40;
                checkDeath(target, char);
            }
        });
    }
}

function checkDeath(target, killer) {
    if (target.hp <= 0 && target.alive) {
        target.alive = false;
        document.getElementById('kill-feed').innerText = `☠️ ${killer.name} قتل ${target.name}!`;
        playIraqiVoiceSound();
    }
}

// الذكاء الاصطناعي للبقية
function updateAI() {
    [...team1.slice(1), ...team2].forEach(bot => {
        if (!bot.alive) return;
        const targets = bot.team === 1 ? team2 : team1;
        const activeTargets = targets.filter(t => t.alive);
        if (activeTargets.length === 0) return;

        const closest = activeTargets[0];
        if (bot.x < closest.x - 100) bot.x += 1;
        if (bot.x > closest.x + 100) bot.x -= 1;

        if (Math.random() < 0.02) shoot(bot);
    });
}

function updateGame() {
    // حركة اللاعب
    if (keys['ArrowUp'] && player.y > 20) player.y -= player.speed;
    if (keys['ArrowDown'] && player.y < canvas.height - 20) player.y += player.speed;
    if (keys['ArrowLeft'] && player.x > 20) player.x -= player.speed;
    if (keys['ArrowRight'] && player.x < canvas.width - 20) player.x += player.speed;

    // حركة الرصاص
    bullets.forEach((b, index) => {
        b.x += b.vx;
        const targets = b.team === 1 ? team2 : team1;
        targets.forEach(t => {
            if (t.alive && Math.hypot(t.x - b.x, t.y - b.y) < t.radius) {
                t.hp -= 20;
                checkDeath(t, player);
                bullets.splice(index, 1);
            }
        });
    });

    updateAI();

    // تحديث الواجهة
    document.getElementById('t1-stats').innerHTML = team1.map(p => `${p.name}: ${p.alive ? p.hp + 'HP' : 'مات'}`).join('<br>');
    document.getElementById('t2-stats').innerHTML = team2.map(p => `${p.name}: ${p.alive ? p.hp + 'HP' : 'مات'}`).join('<br>');
}

function drawGame() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // رسم عناصر بيت عليجان (جدران)
    ctx.fillStyle = '#555';
    ctx.fillRect(canvas.width / 2 - 10, 0, 20, canvas.height - 100);

    // رسم الشخصيات
    team1.forEach(p => p.draw());
    team2.forEach(p => p.draw());

    // رسم الرصاص
    ctx.fillStyle = '#f39c12';
    bullets.forEach(b => {
        ctx.beginPath();
        ctx.arc(b.x, b.y, 4, 0, Math.PI * 2);
        ctx.fill();
    });
}

// حلقة اللعبة المجهزة لأداء عالي جداً (تصل إلى 150 FPS على الشاشات المدعومة)
function gameLoop() {
    updateGame();
    drawGame();
    requestAnimationFrame(gameLoop);
}

requestAnimationFrame(gameLoop);
</script>
</body>
</html>
