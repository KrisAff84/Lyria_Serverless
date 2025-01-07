let songIdx = 0;
const audioPlayer = document.getElementById("audio-player");
const playPauseButton = document.getElementById("play-pause");
const playIcon = document.getElementById("play-icon");
const pauseIcon = document.getElementById("pause-icon");
const skipBackwardButton = document.getElementById("skip-backward");
const skipForwardButton = document.getElementById("skip-forward");

document.addEventListener("DOMContentLoaded", async  () => {
    const data = await fetchData();
    if (data) {
        initializePlayer(data);
    } else {
        console.error("Failed to fetch data");
    }
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

    // Set the first song as active
    if (index === 0) {
        listItem.classList.add("song-list-active");
    }

    // Add an event listener to each song in the list
    listItem.addEventListener("click", () => {
        // Update audio, image, and title on song click
        audioPlayer.src = audioUrls[index];
        songImage.src = imageUrls[index];
        dynamicTitle.textContent = song;

        // Update the active song in the song list
        const listItems = document.querySelectorAll("#song-list ul li");
        listItems.forEach(item => item.classList.remove("song-list-active"));
        listItem.classList.add("song-list-active");

        // Update the song index
        songIdx = index;

        // Play the selected song
        audioPlayer.play();
    });

        songList.appendChild(listItem);
    });


    playPauseButton.addEventListener("click", () => {
        if (audioPlayer.paused) {
            // Call playAudio() and handle the promise
            playAudio()
                .then(() => {
                    // If playAudio succeeds, update icons
                    playIcon.style.display = "none";
                    pauseIcon.style.display = "inline"; // Show pause icon
                })
                .catch(error => {
                    console.error("Autoplay error:", error);
                    // Show the play icon in case of an error
                    playIcon.style.display = "inline";
                    pauseIcon.style.display = "none";
                });
                checkPlayPauseState();
        } else {
            // Pause audio and update icons
            audioPlayer.pause();
            playIcon.style.display = "inline"; // Show play icon
            pauseIcon.style.display = "none";
            checkPlayPauseState();
        }
    });

    skipBackwardButton.addEventListener("click", function () {
        const newIdx = (songIdx - 1 + songTitles.length) % songTitles.length;
        songIdx = newIdx;

        // Update the active song in the song list
        const listItems = document.querySelectorAll("#song-list ul li");
        listItems.forEach(item => item.classList.remove("song-list-active"));
        listItems[newIdx].classList.add("song-list-active");

        // Update the audio player with the new index
        updateAudioPlayer(newIdx);
    });

    skipForwardButton.addEventListener("click", function () {
        const newIdx = (songIdx + 1) % songTitles.length;
        songIdx = newIdx;

        // Update the active song in the song list
        const listItems = document.querySelectorAll("#song-list ul li");
        listItems.forEach(item => item.classList.remove("song-list-active"));
        listItems[newIdx].classList.add("song-list-active");

        // Update the audio player with the new index
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
        playIcon.style.display = "inline"; // Show play icon
        pauseIcon.style.display = "none";
    } else {
        playIcon.style.display = "none";
        pauseIcon.style.display = "inline"; // Show pause icon
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
        playIcon.style.display = "none";
        pauseIcon.style.display = "inline"; // Show pause icon
        audioPlayer.removeEventListener("canplay", onCanPlay);  // Remove the event listener after the first playback
    });

    checkPlayPauseState();
    songIdx = newIdx;
}
