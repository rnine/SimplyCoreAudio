//
//  AMCoreAudioUtilities.h
//  AMCoreAudio
//
//  The functions below were copied and adapted from the AEUtilities.h in "The Amazing Audio Engine"
//  by Michael Tyson on 23/03/2012.
//
//  I merely changed the AE prefix to AM to match the AMCoreAudio framework prefix.
//
//  "The Amazing Audio Engine" is released under a MIT license.
//
//  Added by Ruben Nine on 18/03/14.

#import <AudioToolbox/AudioToolbox.h>

#ifdef __cplusplus
extern "C" {
#endif

/*!
 * Allocate an audio buffer list and the associated mData pointers.
 *
 *  Note: Do not use this utility from within the Core Audio thread (such as inside a render
 *  callback). It may cause the thread to block, inducing audio stutters.
 *
 * @param audioFormat       Audio format describing audio to be stored in buffer list
 * @param frameCount        The number of frames to allocate space for (or 0 to just allocate the list structure itself)
 * @return The allocated and initialised audio buffer list
 */
AudioBufferList *AMAllocateAndInitAudioBufferList(AudioStreamBasicDescription audioFormat, int frameCount);

/*!
 * Create a copy of an audio buffer list
 *
 *  Note: Do not use this utility from within the Core Audio thread (such as inside a render
 *  callback). It may cause the thread to block, inducing audio stutters.
 *
 * @param original          The original AudioBufferList to copy
 * @return The new, copied audio buffer list
 */
AudioBufferList *AMCopyAudioBufferList(AudioBufferList *original);

/*!
 * Free a buffer list and associated mData buffers
 *
 *  Note: Do not use this utility from within the Core Audio thread (such as inside a render
 *  callback). It may cause the thread to block, inducing audio stutters.
 */
void AMFreeAudioBufferList(AudioBufferList *bufferList);

/*!
 * Initialize a pre-allocated audio buffer list structure
 *
 *  Populates the fields in the given audio buffer list. This utility is useful when
 *  allocating an audio buffer list on the stack.
 *
 *  Sample usage:
 *
 *  @code
 *  char audioBufferListSpace[sizeof(AudioBufferList)+sizeof(AudioBuffer)];
 *  AudioBufferList *bufferList = (AudioBufferList*)audioBufferListSpace;
 *  AMInitAudioBufferList(bufferList, sizeof(audioBufferListSpace), &THIS->_audioFormat, THIS->_audioBytes, kAudioBufferSize);
 *  @endcode
 *
 * @param list          Audio buffer list to initialize
 * @param listSize      Size of buffer list structure (eg. "sizeof(list)")
 * @param audioFormat   Audio format describing audio to be stored in buffer list
 * @param data          Optional pointer to a buffer to point the mData pointers within buffer list to.
 *                      If audio format is more than one channel and non-interleaved, the buffer will be
 *                      broken up into even pieces, one for each channel.
 * @param dataSize      Size of 'data' buffer, in bytes.
 */
void AMInitAudioBufferList(AudioBufferList *list, int listSize, AudioStreamBasicDescription audioFormat, void *data, int dataSize);

/*!
 * Get the number of frames in a buffer list
 *
 *  Calculates the frame count in the buffer list based on the given
 *  audio format. Optionally also provides the channel count.
 *
 * @param list          Pointer to an AudioBufferList containing audio
 * @param audioFormat   Audio format describing the audio in the buffer list
 * @param oNumberOfChannels If not NULL, will be set to the number of channels of audio in 'list'
 * @return Number of frames in the buffer list
 */
int AMGetNumberOfFramesInAudioBufferList(AudioBufferList *list, AudioStreamBasicDescription audioFormat, int *oNumberOfChannels);

#ifdef __cplusplus
}
#endif
