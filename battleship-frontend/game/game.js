const parsnip = new URLSearchParams(window.location.search);
if (parsnip.get('role') === 'joiner') {
    state = 'joining'
} else if (parsnip.get('role') === 'host') {
    state = 'waiting'
} else {
    state = 'none'
};

const rotateBtn = document.getElementById('rotate-btn');
shipSelection = document.getElementById('ship-select'); // list for choosing ship to add

function updateVisibility() {
    if (state === 'placing') {
        rotateBtn.style.display = 'block';
        shipSelection.style.display = 'block';
    } else {
        rotateBtn.style.display = 'none';
        shipSelection.style.display = 'none';
    }
}

function rotate() {
    if (playerRotation === "horizontal") {
        playerRotation = "vertical";
        rotateBtn.textContent = "Rotate Ship (V)";
    } else {
        playerRotation = "horizontal";
        rotateBtn.textContent = "Rotate Ship (H)";
    }
}

// state = "placing"; // uncomment to test ship placing functionality
updateVisibility();
console.log(state);
// possible states: 'joining', 'waiting', 'placing', 'playing not turn', 'playing turn', 'none'
 
document.getElementById('lobbyname').textContent = parsnip.get("game") + "'s game";

let playerShips = Array(100).fill(false);
let playerRotation = "horizontal";

const playerGrid = document.querySelector('#player-board .grid');
const opponentGrid = document.querySelector('#opponent-board .grid');

for (let i = 0; i < 100; i++) { // player grid
    const playerCell = document.createElement('div');
    playerCell.classList.add('cell');
    playerCell.addEventListener('click', () => {
        if (state === 'placing') {
            const shipLength = parseInt(shipSelection.value);

            const col = i % 10;
            const row = Math.floor(i / 10);
            
            if (playerRotation == "vertical" && row + shipLength > 10) {
                console.log("oob")
                return;
            } else if (playerRotation == "horizontal" && col + shipLength > 10) {
                console.log("oob")
                return;
            } 

            let validity = true;

            for (let x = 0; x < shipLength; x++) { // check for validitiy. highk validity check should be on the server but valentin is a CHUD anbd wont work on it
                let targetIndex;

                if (playerRotation == "horizontal") {
                    targetIndex = i + x;
                    if (playerShips[targetIndex] == true) {
                        validity = false;
                        break;
                    }  
                } else {
                    targetIndex = i + (10 * x); 
                    if (playerShips[targetIndex] == true) {
                        validity = false;
                        break;
                    }  
                } 
            }
            if (validity === true) {
                const selectedShip = shipSelection.selectedIndex;
                shipSelection.remove(selectedShip);
                for (let x = 0; x < shipLength; x++) { // place
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
                if (shipSelection.options.length === 0) {
                    console.log("all ships placed");
                    state = "playing not turn";
                    updateVisibility();
                }
            } else {
                console.log("ship in the way");
            }
        }
    });

    playerGrid.appendChild(playerCell);
}

for (let i = 0; i < 100; i++) { // enemy grid
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

if (state === 'none') { // failsafe
    alert("you shouldn't be here....");
    window.location.href = '../lobby/index.html';
}

// works for now, dummy code. will implement networking later, gonna do lobby now
// i dont know how it's working bro how th eufck did i write 125 lines of code on this shit file nothing makes sense why it works this should NOT be working im crine