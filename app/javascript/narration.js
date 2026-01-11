// Support both regular page loads and Turbo navigation
function initializeNarration() {
    const narrateBtn = document.getElementById('narrateBtn');
    const btnIcon = document.getElementById('btnIcon');
    const btnText = document.getElementById('btnText');
    const controlsExpanded = document.getElementById('controlsExpanded');
    const voiceSelect = document.getElementById('voiceSelect');
    const rateControl = document.getElementById('rateControl');
    const pitchControl = document.getElementById('pitchControl');
    const rateValue = document.getElementById('rateValue');
    const pitchValue = document.getElementById('pitchValue');

    // Exit if elements don't exist or already initialized
    if (!narrateBtn || narrateBtn.dataset.narrationInitialized) return;
    narrateBtn.dataset.narrationInitialized = 'true';


            let currentUtterance = null;
            let isPaused = false;
            let isSpeaking = false;


    // Load available voices
    function loadVoices() {
        const voices = window.speechSynthesis.getVoices();
        console.log('Loading voices, found:', voices.length);
        
        if (voices.length === 0) {
            console.log('No voices available yet');
            return;
        }
        
        voiceSelect.innerHTML = '';
        voices.forEach((voice, index) => {
            const option = document.createElement('option');
            option.value = index;
            option.textContent = `${voice.name} (${voice.lang})`;
            voiceSelect.appendChild(option);
        });
        
        console.log('Populated dropdown with', voices.length, 'voices');
    }

    // Try loading voices immediately and set up listener
    if (typeof speechSynthesis !== 'undefined') {
        if (speechSynthesis.onvoiceschanged !== undefined) {
            speechSynthesis.onvoiceschanged = loadVoices;
        }
        loadVoices();
        
        // Fallback: retry after delay if no voices loaded
        setTimeout(() => {
            if (voiceSelect.options.length === 0) {
                console.log('Retrying voice load');
                loadVoices();
            }
        }, 100);
    }


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
            console.log('=== Getting text to read ===');
            
            // First, try to find the specific chapter content div
            let contentDiv = document.querySelector('.chapter-content');
            
            if (contentDiv) {
                console.log('Found .chapter-content div');
                
                // Get only text from actual text nodes and allowed elements
                // This completely bypasses form controls
                const textParts = [];
                
                function extractText(element) {
                    // Skip if this is a control element
                    if (element.classList && 
                        (element.classList.contains('narration-controls') ||
                         element.classList.contains('controls-expanded'))) {
                        return;
                    }
                    
                    // Skip form controls entirely
                    const tagName = element.tagName;
                    if (tagName === 'SELECT' || tagName === 'INPUT' || 
                        tagName === 'BUTTON' || tagName === 'OPTION' ||
                        tagName === 'LABEL' || tagName === 'NAV' || 
                        tagName === 'FOOTER' || tagName === 'SCRIPT' || 
                        tagName === 'STYLE') {
                        return;
                    }
                    
                    // If it's a text node, grab it
                    if (element.nodeType === Node.TEXT_NODE) {
                        const text = element.textContent.trim();
                        if (text.length > 0) {
                            textParts.push(text);
                        }
                    } else if (element.childNodes) {
                        // Recursively process children
                        Array.from(element.childNodes).forEach(child => extractText(child));
                    }
                }
                
                extractText(contentDiv);
                const text = textParts.join(' ').replace(/\s+/g, ' ').trim();
                
                console.log('Text length:', text.length);
                console.log('Text preview:', text.substring(0, 100));
                
                if (text.length > 0) {
                    return text;
                }
            }
            
            // Fallback: try section.chapter but exclude the navigation parts
            const chapterSection = document.querySelector('section.chapter');
            if (chapterSection) {
                console.log('Using section.chapter fallback');
                const h1 = chapterSection.querySelector('h1');
                const contentDiv = chapterSection.querySelector('.chapter-content');
                
                let text = '';
                if (h1) {
                    text += h1.innerText.trim() + '. ';
                }
                if (contentDiv) {
                    // Use the same extraction method
                    const textParts = [];
                    function extractText(element) {
                        if (element.nodeType === Node.TEXT_NODE) {
                            const txt = element.textContent.trim();
                            if (txt.length > 0) textParts.push(txt);
                        } else if (element.childNodes) {
                            Array.from(element.childNodes).forEach(child => extractText(child));
                        }
                    }
                    extractText(contentDiv);
                    text += textParts.join(' ').replace(/\s+/g, ' ').trim();
                }
                
                console.log('Fallback text length:', text.length);
                if (text.length > 0) {
                    return text;
                }
            }
            
            console.log('ERROR: No content found to read');
            return '';
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
            const selectedVoiceIndex = parseInt(voiceSelect.value);
            const selectedVoice = voices[selectedVoiceIndex];
            
            console.log('Selected voice index:', selectedVoiceIndex);
            console.log('Selected voice:', selectedVoice ? selectedVoice.name : 'none');
            
            if (selectedVoice) {
                currentUtterance.voice = selectedVoice;
            }
            currentUtterance.rate = parseFloat(rateControl.value);
            currentUtterance.pitch = parseFloat(pitchControl.value);
            
            console.log('Starting narration with rate:', currentUtterance.rate, 'pitch:', currentUtterance.pitch);

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
}

// Initialize on both DOMContentLoaded and turbo:load
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeNarration);
} else {
    initializeNarration();
}

// Also support Turbo navigation
document.addEventListener('turbo:load', initializeNarration);
document.addEventListener('turbo:render', initializeNarration);