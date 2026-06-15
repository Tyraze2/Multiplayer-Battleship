const parsnip = new URLSearchParams(window.location.search);
// if (parsnip.get('role') === 'joiner') {
//     state = 'joining'
// } else if (parsnip.get('role') === 'host') {
//     state = 'waiting'
// } else {
//     state = 'none'
// };

const rotateBtn = document.getElementById('rotate-btn');
shipSelection = document.getElementById('ship-select'); // list for choosing ship to add

function rotate() {
    if (playerRotation === "horizontal") {
        playerRotation = "vertical";
    } else {
        playerRotation = "horizontal";
    }
}

function updateVisibility() {
    if (state === 'placing') {
        rotateBtn.style.display = 'block';
        shipSelection.style.display = 'block';
    } else {
        rotateBtn.style.display = 'none';
        shipSelection.style.display = 'none';
    }
}

state = "placing"; // temp to test ship placement functionality as i work on it at 23:15 with brevet in effectively 2 days and not having revised for shit lmaoo #cooked
updateVisibility();
console.log(state);
// possible states: 'joining', 'waiting', 'placing', 'playing not turn', 'playing turn', 'none'
 
document.getElementById('lobbyname').textContent = parsnip.get("game") + "'s game";

let playerShips = Array(100).fill(false);
let playerRotation = "horizontal";

const playerGrid = document.querySelector('#player-board .grid');
const opponentGrid = document.querySelector('#opponent-board .grid');

for (let i = 0; i < 100; i++) {
    const playerCell = document.createElement('div');
    playerCell.classList.add('cell');
    playerCell.addEventListener('click', () => {
        if (state === 'placing') {
            const shipLength = parseInt(shipSelection.length);

            const col = i % 10;
            const row = Math.floor(i / 10);
            
            if (playerRotation == "vertical" && row + shipLength > 10) {
                console.log("oob")
                return;
            } else if (playerRotation == "horizontal" && col + shipLength > 10) {
                console.log("oob")
                return;
            }
            
            for (let x = 0; x < shipLength; x++) {
                let targetIndex;
                
                if (playerRotation == "horizontal") {
                    targetIndex = i + x;
                } else {
                    targetIndex = i + (10 * x); 
                }
                
                playerShips[targetIndex] = true;
                
                const targetCell = playerGrid.children[targetIndex];
                if (targetCell) {
                    targetCell.style.backgroundColor = 'blue';
                }
                console.log(`placed ship at ${i} of length ${shipLength} with orientation ${playerRotation}`);
            }
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