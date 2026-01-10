   const narrateBtn = document.getElementById('narrateBtn');
        const btnIcon = document.getElementById('btnIcon');
        const btnText = document.getElementById('btnText');
        const controlsExpanded = document.getElementById('controlsExpanded');
        const voiceSelect = document.getElementById('voiceSelect');
        const rateControl = document.getElementById('rateControl');
        const pitchControl = document.getElementById('pitchControl');
        const rateValue = document.getElementById('rateValue');
        const pitchValue = document.getElementById('pitchValue');

        let currentUtterance = null;
        let isPaused = false;
        let isSpeaking = false;

        // Load available voices
        function loadVoices() {
            const voices = window.speechSynthesis.getVoices();
            voiceSelect.innerHTML = '';
            
            voices.forEach((voice, index) => {
                const option = document.createElement('option');
                option.value = index;
                option.textContent = `${voice.name} (${voice.lang})`;
                voiceSelect.appendChild(option);
            });
        }

        // Load voices when they're ready
        if (speechSynthesis.onvoiceschanged !== undefined) {
            speechSynthesis.onvoiceschanged = loadVoices;
        }
        loadVoices();

        // Update rate value display
        rateControl.addEventListener('input', (e) => {
            rateValue.textContent = e.target.value;
        });

        // Update pitch value display
        pitchControl.addEventListener('input', (e) => {
            pitchValue.textContent = e.target.value;
        });

        // Get text content to narrate
        function getTextToRead() {
            // You can customize this selector to target specific content
            // For example: document.querySelector('main').innerText
            // or multiple sections: Array.from(document.querySelectorAll('p, h1, h2')).map(el => el.innerText).join('. ')
            return document.body.innerText;
        }

        // Start narration
        function startNarration() {
            const textToRead = getTextToRead();
            
            if (!textToRead.trim()) {
                alert('No text content found to narrate.');
                return;
            }

            currentUtterance = new SpeechSynthesisUtterance(textToRead);
            
            // Apply settings
            const voices = window.speechSynthesis.getVoices();
            currentUtterance.voice = voices[voiceSelect.value];
            currentUtterance.rate = parseFloat(rateControl.value);
            currentUtterance.pitch = parseFloat(pitchControl.value);

            // Event handlers
            currentUtterance.onstart = () => {
                isSpeaking = true;
                narrateBtn.classList.add('speaking');
                btnIcon.textContent = '⏸️';
                btnText.textContent = 'Pause';
            };

            currentUtterance.onend = () => {
                isSpeaking = false;
                isPaused = false;
                narrateBtn.classList.remove('speaking', 'paused');
                btnIcon.textContent = '🔊';
                btnText.textContent = 'Read Page';
            };

            currentUtterance.onerror = (event) => {
                console.error('Speech synthesis error:', event);
                isSpeaking = false;
                isPaused = false;
                narrateBtn.classList.remove('speaking', 'paused');
                btnIcon.textContent = '🔊';
                btnText.textContent = 'Read Page';
            };

            window.speechSynthesis.speak(currentUtterance);
        }

        // Pause narration
        function pauseNarration() {
            window.speechSynthesis.pause();
            isPaused = true;
            narrateBtn.classList.remove('speaking');
            narrateBtn.classList.add('paused');
            btnIcon.textContent = '▶️';
            btnText.textContent = 'Resume';
        }

        // Resume narration
        function resumeNarration() {
            window.speechSynthesis.resume();
            isPaused = false;
            narrateBtn.classList.remove('paused');
            narrateBtn.classList.add('speaking');
            btnIcon.textContent = '⏸️';
            btnText.textContent = 'Pause';
        }

        // Stop narration
        function stopNarration() {
            window.speechSynthesis.cancel();
            isSpeaking = false;
            isPaused = false;
            narrateBtn.classList.remove('speaking', 'paused');
            btnIcon.textContent = '🔊';
            btnText.textContent = 'Read Page';
        }

        // Main button click handler
        narrateBtn.addEventListener('click', () => {
            if (!isSpeaking && !isPaused) {
                // Start new narration
                startNarration();
                controlsExpanded.classList.add('active');
            } else if (isSpeaking && !isPaused) {
                // Pause current narration
                pauseNarration();
            } else if (isPaused) {
                // Resume narration
                resumeNarration();
            }
        });

        // Double-click to stop
        narrateBtn.addEventListener('dblclick', () => {
            stopNarration();
            controlsExpanded.classList.remove('active');
        });

        // Allow settings changes during playback
        voiceSelect.addEventListener('change', () => {
            if (isSpeaking || isPaused) {
                stopNarration();
                setTimeout(startNarration, 100);
            }
        });