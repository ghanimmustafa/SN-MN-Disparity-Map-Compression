MEMORY_WORD_BITS = 128;

if ( length(MATLAB_memory_words) > 1)
    tic;
    
    encoded_bitstream = cat(2, MATLAB_memory_words{2},MATLAB_memory_words{1});
    for i = 2: (10) % for i = 2: (length(MATLAB_memory_words) - 1)
        
        if( mod(i,1000) == 0)
            
            current_bitstream_words = length(encoded_bitstream)/MEMORY_WORD_BITS;
            remaining_words = length(MATLAB_memory_words) - current_bitstream_words;
            
            fprintf(' %i many memory words are combined, %i many is left\n',current_bitstream_words, remaining_words);
            elapsed_time = toc;
            tic;
            fprintf(' The total process is expected to terminate after %.2f min(s)\n',elapsed_time * (remaining_words/1000)/60);
        end

        encoded_bitstream = cat(2, MATLAB_memory_words{i+1},encoded_bitstream);


    end
    
else
    
    encoded_bitstream = MATLAB_memory_words{1};

end