function MatrixRain(config) {
    const canvas = document.getElementById('matrix-rain');
    const ctx = canvas.getContext('2d');
    let columns, drops, speeds, grid, prevHeads;

    function init() {
        canvas.width = canvas.offsetWidth;
        canvas.height = canvas.offsetHeight;
        columns   = Math.floor(canvas.width / config.fontSize);
        drops     = Array.from({length: columns}, () => Math.random() * -canvas.height / config.fontSize);
        speeds    = Array.from({length: columns}, () => config.speedMin + Math.random() * (config.speedMax - config.speedMin));
        grid      = Array.from({length: columns}, () => ({}));
        prevHeads = new Array(columns).fill(-1);
        ctx.fillStyle = config.bgColor;
        ctx.fillRect(0, 0, canvas.width, canvas.height);
    }

    let lastTime = 0;

    function draw(time) {
        requestAnimationFrame(draw);
        if (time - lastTime < config.frameDelay) return;
        lastTime = time;

        ctx.globalAlpha = config.fadeSpeed;
        ctx.fillStyle = config.bgColor;
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        ctx.globalAlpha = 1;
        ctx.font = config.fontSize + 'px monospace';

        for (let i = 0; i < columns; i++) {
            const x    = i * config.fontSize;
            const head = Math.floor(drops[i]);

            ctx.fillStyle = config.trailColor;
            for (let r = Math.max(0, prevHeads[i]); r < head; r++) {
                if (!grid[i][r]) grid[i][r] = config.chars[Math.floor(Math.random() * config.chars.length)];
                ctx.fillText(grid[i][r], x, r * config.fontSize);
            }

            if (head >= 0) {
                if (!grid[i][head]) grid[i][head] = config.chars[Math.floor(Math.random() * config.chars.length)];
                ctx.fillStyle = config.headColor;
                ctx.fillText(grid[i][head], x, head * config.fontSize);
            }

            prevHeads[i] = head;

            if (drops[i] * config.fontSize > canvas.height && Math.random() < config.resetChance) {
                drops[i]     = 0;
                prevHeads[i] = -1;
            }
            drops[i] += speeds[i];
        }
    }

    let lastWidth = canvas.offsetWidth;
    window.addEventListener('resize', () => {
        if (canvas.offsetWidth !== lastWidth) {
            lastWidth = canvas.offsetWidth;
            init();
        }
    });

    init();
    draw();
}
