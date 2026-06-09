let state = 'placing'; // 'placing', 'playing not turn', 'playing turn', 'none'
const playerShips = Array(100).fill(false);

const playerGrid = document.querySelector('#player-board .grid');
const opponentGrid = document.querySelector('#opponent-board .grid');

for (let i = 0; i < 100; i++) {
    const playerCell = document.createElement('div');
    playerCell.classList.add('cell');
    playerCell.addEventListener('click', () => {
        if (state === 'placing') {
            playerCell.style.backgroundColor = 'blue';
            playerShips[i] = true; 
            console.log(`placed ship at ${i}`);
        }
    });

    playerGrid.appendChild(playerCell);
}

for (let i = 0; i < 100; i++) {
    const opponentCell = document.createElement('div');
    opponentCell.classList.add('cell');
    
    opponentCell.addEventListener('click', () => {
        if (state === 'playing turn') {
            opponentCell.style.backgroundColor = 'red';
            console.log(`attacked ${i}`);
        } else if (state === 'placing') {
            console.log("invalid move");
        }
    });
    opponentGrid.appendChild(opponentCell);
}

if (state === 'none') {
    alert("You shouldn't be here....");
    window.location.href = '../lobby/index.html';
}

// works for now, dummy code. will implement networking later, gonna do lobby now