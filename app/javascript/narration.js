// Narration functionality with voice persistence
(function() {
    'use strict';
    
    function initializeNarration() {
        console.log('Initializing narration...');
        
        const narrateBtn = document.getElementById('narrateBtn');
        const btnIcon = document.getElementById('btnIcon');
        const btnText = document.getElementById('btnText');
        const controlsExpanded = document.getElementById('controlsExpanded');
        const voiceSelect = document.getElementById('voiceSelect');
        const rateControl = document.getElementById('rateControl');
        const pitchControl = document.getElementById('pitchControl');
        const rateValue = document.getElementById('rateValue');
        const pitchValue = document.getElementById('pitchValue');

        // Exit if elements don't exist
        if (!narrateBtn) {
            console.error('narrateBtn not found!');
            return;
        }
        
        // Exit if already initialized
        if (narrateBtn.dataset.narrationInitialized) {
            console.log('Already initialized, skipping...');
            return;
        }
        
        narrateBtn.dataset.narrationInitialized = 'true';
        console.log('Elements found, setting up...');

        let currentUtterance = null;
        let isPaused = false;
        let isSpeaking = false;

        // Load saved preferences from localStorage
        function loadSavedPreferences() {
            const savedVoiceName = localStorage.getItem('narration_voice_name');
            const savedRate = localStorage.getItem('narration_rate');
            const savedPitch = localStorage.getItem('narration_pitch');

            if (savedRate) {
                rateControl.value = savedRate;
                rateValue.textContent = savedRate;
            }
            if (savedPitch) {
                pitchControl.value = savedPitch;
                pitchValue.textContent = savedPitch;
            }

            return savedVoiceName;
        }

        // Save preferences to localStorage
        function savePreferences() {
            const voices = window.speechSynthesis.getVoices();
            const selectedVoiceIndex = parseInt(voiceSelect.value);
            const selectedVoice = voices[selectedVoiceIndex];
            
            if (selectedVoice) {
                localStorage.setItem('narration_voice_name', selectedVoice.name);
            }
            localStorage.setItem('narration_rate', rateControl.value);
            localStorage.setItem('narration_pitch', pitchControl.value);
        }

        // Load available voices
        function loadVoices() {
            const voices = window.speechSynthesis.getVoices();
            console.log('Loading voices, found:', voices.length);
            
            if (voices.length === 0) {
                console.log('No voices available yet');
                return;
            }
            
            voiceSelect.innerHTML = '';
            const savedVoiceName = loadSavedPreferences();
            let voiceFound = false;
            
            voices.forEach((voice, index) => {
                const option = document.createElement('option');
                option.value = index;
                option.textContent = `${voice.name} (${voice.lang})`;
                
                if (savedVoiceName && voice.name === savedVoiceName) {
                    option.selected = true;
                    voiceFound = true;
                    console.log('Restored saved voice:', savedVoiceName);
                }
                
                voiceSelect.appendChild(option);
            });
            
            if (!voiceFound && savedVoiceName) {
                console.log('Saved voice not found:', savedVoiceName);
            }
            
            console.log('Populated dropdown with', voices.length, 'voices');
        }

        // Try loading voices
        if (typeof speechSynthesis !== 'undefined') {
            if (speechSynthesis.onvoiceschanged !== undefined) {
                speechSynthesis.onvoiceschanged = loadVoices;
            }
            loadVoices();
            
            setTimeout(() => {
                if (voiceSelect.options.length === 0) {
                    console.log('Retrying voice load');
                    loadVoices();
                }
            }, 100);
        }

        // Update rate value display and save
        rateControl.addEventListener('input', (e) => {
            rateValue.textContent = e.target.value;
            savePreferences();
        });

        // Update pitch value display and save
        pitchControl.addEventListener('input', (e) => {
            pitchValue.textContent = e.target.value;
            savePreferences();
        });

        // Save voice selection when changed
        voiceSelect.addEventListener('change', () => {
            savePreferences();
            if (isSpeaking || isPaused) {
                stopNarration();
                setTimeout(startNarration, 100);
            }
        });

        // Get text content to narrate
        function getTextToRead() {
            console.log('Getting text to read...');
            
            let contentDiv = document.querySelector('.chapter-content');
            
            if (contentDiv) {
                const textParts = [];
                
                function extractText(element) {
                    if (element.classList && 
                        (element.classList.contains('narration-controls') ||
                         element.classList.contains('controls-expanded'))) {
                        return;
                    }
                    
                    const tagName = element.tagName;
                    if (tagName === 'SELECT' || tagName === 'INPUT' || 
                        tagName === 'BUTTON' || tagName === 'OPTION' ||
                        tagName === 'LABEL' || tagName === 'NAV' || 
                        tagName === 'FOOTER' || tagName === 'SCRIPT' || 
                        tagName === 'STYLE') {
                        return;
                    }
                    
                    if (element.nodeType === Node.TEXT_NODE) {
                        const text = element.textContent.trim();
                        if (text.length > 0) {
                            textParts.push(text);
                        }
                    } else if (element.childNodes) {
                        Array.from(element.childNodes).forEach(child => extractText(child));
                    }
                }
                
                extractText(contentDiv);
                const text = textParts.join(' ').replace(/\s+/g, ' ').trim();
                
                console.log('Text length:', text.length);
                
                if (text.length > 0) {
                    return text;
                }
            }
            
            console.log('No content found');
            return 'This is a test. If you can hear this, the narration is working.';
        }

        // Start narration
        function startNarration() {
            console.log('Starting narration...');
            const textToRead = getTextToRead();
            
            if (!textToRead.trim()) {
                alert('No text content found to narrate.');
                return;
            }

            currentUtterance = new SpeechSynthesisUtterance(textToRead);
            
            const voices = window.speechSynthesis.getVoices();
            const selectedVoiceIndex = parseInt(voiceSelect.value);
            const selectedVoice = voices[selectedVoiceIndex];
            
            if (selectedVoice) {
                currentUtterance.voice = selectedVoice;
            }
            currentUtterance.rate = parseFloat(rateControl.value);
            currentUtterance.pitch = parseFloat(pitchControl.value);

            currentUtterance.onstart = () => {
                console.log('Speech started');
                isSpeaking = true;
                narrateBtn.classList.add('speaking');
                btnIcon.textContent = '⏸️';
                btnText.textContent = 'Pause';
            };

            currentUtterance.onend = () => {
                console.log('Speech ended');
                isSpeaking = false;
                isPaused = false;
                narrateBtn.classList.remove('speaking', 'paused');
                btnIcon.textContent = '🔊';
                btnText.textContent = 'Read Page';
            };

            currentUtterance.onerror = (event) => {
                console.error('Speech error:', event);
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
            console.log('Pausing...');
            window.speechSynthesis.pause();
            isPaused = true;
            narrateBtn.classList.remove('speaking');
            narrateBtn.classList.add('paused');
            btnIcon.textContent = '▶️';
            btnText.textContent = 'Resume';
        }

        // Resume narration
        function resumeNarration() {
            console.log('Resuming...');
            window.speechSynthesis.resume();
            isPaused = false;
            narrateBtn.classList.remove('paused');
            narrateBtn.classList.add('speaking');
            btnIcon.textContent = '⏸️';
            btnText.textContent = 'Pause';
        }

        // Stop narration
        function stopNarration() {
            console.log('Stopping...');
            window.speechSynthesis.cancel();
            isSpeaking = false;
            isPaused = false;
            narrateBtn.classList.remove('speaking', 'paused');
            btnIcon.textContent = '🔊';
            btnText.textContent = 'Read Page';
        }

        // Main button click handler
        narrateBtn.addEventListener('click', () => {
            console.log('Button clicked! isSpeaking:', isSpeaking, 'isPaused:', isPaused);
            
            if (!isSpeaking && !isPaused) {
                startNarration();
                controlsExpanded.classList.add('active');
            } else if (isSpeaking && !isPaused) {
                pauseNarration();
            } else if (isPaused) {
                resumeNarration();
            }
        });

        // Double-click to stop
        narrateBtn.addEventListener('dblclick', () => {
            console.log('Double-clicked!');
            stopNarration();
            controlsExpanded.classList.remove('active');
        });
        
        console.log('Narration initialized successfully!');
    }

    // Initialize on different events
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initializeNarration);
    } else {
        initializeNarration();
    }

    document.addEventListener('turbo:load', initializeNarration);
    document.addEventListener('turbo:render', initializeNarration);
})();