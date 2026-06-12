const parsnip = new URLSearchParams(window.location.search);
if (parsnip.get('role') === 'joiner') {
    state = 'joining'
} else if (parsnip.get('role') === 'host') {
    state = 'waiting'
} else {
    state = 'none'
};
console.log(state);
// possible states: 'joining', 'waiting', 'placing', 'playing not turn', 'playing turn', 'none'
 
document.getElementById('lobbyname').textContent = parsnip.get("game") + "'s game";

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
        } else {
            console.log("cannot play when not your turn!");
        }
    });
    opponentGrid.appendChild(opponentCell);
}

if (state === 'none') {
    alert("you shouldn't be here....");
    window.location.href = '../lobby/index.html';
}

// works for now, dummy code. will implement networking later, gonna do lobby now