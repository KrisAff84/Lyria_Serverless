let songIdx = 0;
const audioPlayer = document.getElementById("audio-player");
const playPauseButton = document.getElementById("play-pause");
const apiEndpoint = "https://d1dm5md3alz8xa.cloudfront.net/dev/index"
const skipBackwardButton = document.getElementById("skip-backward");
const skipForwardButton = document.getElementById("skip-forward");

async function fetchData() {
    const response = await fetch(apiEndpoint);
    if (!response.ok) {
        console.error("Failed to fetch data:", response);
        return;
    }
    return response.json();
}

document.addEventListener("DOMContentLoaded", async  () => {
    const data = await fetchData();
    initializePlayer(data);
});

function initializePlayer(data) {
    // Get the song list, audio URLs, and image URLs from the data

    songTitles = data.song_list;
    audioUrls = data.audio_urls;
    imageUrls = data.image_urls;
    const initialSongTitle = data.current_title;
    const initialImage = data.current_image_url;
    const initialAudio = data.current_audio_url;


    // Set initial Song Title
    const dynamicTitle = document.getElementById("dynamic-title");
    dynamicTitle.innerText = initialSongTitle;

    // Set initial Song Image
    const songImage = document.getElementById("song-image");
    songImage.src = initialImage;

    // Set initial audio source
    audioPlayer.src = initialAudio;

    // Populate the song list
    const songList = document.querySelector("#song-list ul");
    songTitles.forEach((song, index) => {
        const listItem = document.createElement("li");
        listItem.textContent = song;

    // Add an event listener to each song in the list
    listItem.addEventListener("click", () => {
        // Update audio, image, and title on song click
        audioPlayer.src = audioUrls[index];
        songImage.src = imageUrls[index];
        dynamicTitle.textContent = song;

        // Play the selected song
        audioPlayer.play();
    });

        songList.appendChild(listItem);
    });

    playPauseButton.addEventListener("click", function () {
        playAudio()
            .then(() => {
                // If the audio is playing, show the pause icon
                if (audioPlayer.paused) {
                    playPauseButton.innerHTML = `<ion-icon name="play-circle"></ion-icon>`;
                } else {
                    playPauseButton.innerHTML = `<ion-icon name="pause-circle"></ion-icon>`;
                }
                checkPlayPauseState();
            })
            .catch(error => {
                console.error("Autoplay error:", error);
                // Show the play icon and let the user initiate playback
                playPauseButton.innerHTML = `<ion-icon name="play-circle"></ion-icon>`;
                checkPlayPauseState();
            });
    });

    skipBackwardButton.addEventListener("click", function () {
        const newIdx = (songIdx - 1 + songTitles.length) % songTitles.length;
        songIdx = newIdx;
        updateAudioPlayer(newIdx);
    });

    skipForwardButton.addEventListener("click", function () {
        const newIdx = (songIdx + 1) % songTitles.length;
        songIdx = newIdx;
        updateAudioPlayer(newIdx);
    });

    // Handle the ended event to move to the next song
    audioPlayer.addEventListener("ended", function () {
        const newIdx = (songIdx + 1) % songTitles.length;
        songIdx = newIdx;
        updateAudioPlayer(newIdx);
    });

    audioPlayer.addEventListener("playing", function () {
        checkPlayPauseState();
    });

    audioPlayer.addEventListener("pause", function () {
        checkPlayPauseState();
    });
}

function checkPlayPauseState() {
    if (audioPlayer.paused) {
        playPauseButton.innerHTML = `<ion-icon name="play-circle"></ion-icon>`;
    } else {
        playPauseButton.innerHTML = `<ion-icon name="pause-circle"></ion-icon>`;
    }
}

function playAudio() {
    return new Promise((resolve, reject) => {
        if (audioPlayer.paused) {
            audioPlayer.play();
            resolve();
        } else {
            audioPlayer.pause();
        }
    });
}

function togglePlayPause() {
    if (audioPlayer.paused) {
        audioPlayer.play();
    } else {
        audioPlayer.pause();
    }
}

function updateAudioPlayer(newIdx) {
    document.getElementById("dynamic-title").innerText = songTitles[newIdx];
    document.getElementById("song-image").src = imageUrls[newIdx];

    // Update both the audio file and the audio player source
    audioPlayer.src = audioUrls[newIdx];

    // Handle the canplay event to start playback
    audioPlayer.addEventListener("canplay", function onCanPlay() {
        audioPlayer.play();
        playPauseButton.innerHTML = `<ion-icon name="pause-circle"></ion-icon>`;
        audioPlayer.removeEventListener("canplay", onCanPlay);  // Remove the event listener after the first playback
    });

    checkPlayPauseState();
    songIdx = newIdx;
}

