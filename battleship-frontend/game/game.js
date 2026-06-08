const playerGrid = document.querySelector('#player-board .grid');
const opponentGrid = document.querySelector('#opponent-board .grid');

for (let i = 0; i < 100; i++) {
    const playerCell = document.createElement('div');
    playerCell.classList.add('square');
    playerGrid.appendChild(playerCell);

    const opponentCell = document.createElement('div');
    opponentCell.classList.add('square');
    opponentGrid.appendChild(opponentCell);
}

// ok we're working... i think i understand the code. AI is crazy nowadays i feel kinda like a passenger. i understand it tho. i could probably rewrite this myself if i had to.
// good for my first time with html and javascript and css tho!!