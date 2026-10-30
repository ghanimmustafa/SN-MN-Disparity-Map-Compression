for im = 1:length(GT_DMs)
image_name = round(GT_DMs{im},1);  %imread('lena512.png');
image_vector = reshape(image_name',1,numel(image_name))';
image = image_vector;%[145,145,145,145,145,145,145,205,64,145,145,145,145,145,145,145]; %uint8(test_img);
[height,width] = size(image_name);

maxval = max(image);
fraction_bits = 4;
max_integer_bits = ceil(log2(max(max(image))));
image = fi(image,0,max_integer_bits+fraction_bits,fraction_bits);
image = image.data;

bit_depth = ceil(log2(maxval)) + fraction_bits;
encoded_bitstream = zeros(1,length(image_vector) * bit_depth);
bitstream_index = 0;
%% initialize JPEG-LS step 1
near = 0; %center region; default, lossless
Range = maxval + 1; %percision; default, lossless,  = 256
qbpp = bit_depth; %bit depth, from image, = 8
bpp = bit_depth;%max(2,ceil(log2(maxval+1))); %bit depth, used for limit calc, = 8
limit = 2*(bpp + max(qbpp,bpp)); %limit of code length, = 32
%quantization regions; default 8-qbpp
T1 = 3; T2 = 7; T3 = 21;
%sign variable for adaptive correction
sign = 1; %1 = pos, 0 = neg
error_value = 0; %computed error value residual
%when to reset adaptive parameter counter
reset = 64; %default, lossless
%adaptive correction parameters
C = zeros(1,365); % (cumulative) prediction correction values
B = zeros(1,365); % bias
N = ones(1,367); 
Nn = zeros(1,367); %for run mode, only need last 2 indexes
A_init = max(2,floor((Range+2^5)/2^6));
A = ones(1,367) * A_init; %empty array A
%closed range for variable C forall indexes
min_C = -128;
max_C = 127;
%run mode variables
run_count = 0; %how long the run is
run_index = 1; %index of run vector J (start at 1 for matlab
run_index_fixed = 1; %refer to this index when coding run intfor. variable
run_value = 0; %comparison variable to check equality of x during run
run_interupt_type = 0; %coding identifier for run length
J = [0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3, ... 
    4,4,5,5,6,6,7,7,8,9,10,11,12,13,14,15];
%context map variables
num_gradients = 729; %based on quantization regions; defaunt 8qbpp
map_size = 365; %size of context map; default
total_quantized_gradients = cell(1,num_gradients); %empty cell of gradients
context_map = cell(1,map_size);
init_q1 = -4; init_q2 = -4; init_q3 = -4;
j = 2;
for i = 1:num_gradients %fill all defined quantized values
    total_quantized_gradients{i} = [init_q1,init_q2,init_q3];
    if(init_q3 < 4)
    init_q3 = init_q3 + 1;
    else
        init_q3 = -4;
        init_q2 = init_q2 + 1;
    end
    
    if(init_q2 > 4)
    init_q1 = init_q1 + 1;
    init_q2 = -4;
    end
end
for i = 1:map_size %fill map with quantized triplets w/o run mode
    
    if(total_quantized_gradients{i}(1) == total_quantized_gradients{i}(2) && ...
            total_quantized_gradients{i}(1) == total_quantized_gradients{i}(3) ...
            && total_quantized_gradients{i}(1) == 0)
        
        context_map{1} = total_quantized_gradients{i}; %[0 0 0] for run length mode
        
    else
        context_map{j} = total_quantized_gradients{i};
        j = j + 1;
    end
    
end
map_index = 1; %pointer index for map -> corrective parameters
var_k = 0; %Golomb variable k
end_of_line = 0; %designate end of line
mode = 0; %what operating mode
%0 - normal mode
%1 - run mode
%2 - run coding
a_from_previous_line = 0; %save previous first 'a' value
%encoded_bitstream = char.empty; %final bitstream 

%% start image processing
cnt = 0;

for index = 1:length(image) %for all samples of image
    x = image(index); %get new sample
    if(mod(index,width) == 0)
        cnt = cnt + 1;
        if(mod(cnt,10) == 0)
            fprintf(' %i many lines are processed, %i  lines  left  \n',cnt,height-cnt);
            CR = 100 * (((cnt * width * bit_depth) - bitstream_index))/((cnt * width * bit_depth));
            fprintf('Frame index = %i, Current Compression Ratio = %.2f\n',im,CR);
        
        end

    end
    %% normal mode
    if(mode == 0) %normal mode
        %% gradient calculation, step 2
        if(index <= width) %if on the first row of the image
            b = 0; c = 0; d = 0;
            if(1 == mod(index,width)) %if also on first col
                a = b;
            else
                a = image(index-1);
            end
        else
            if(1 == mod(index,width)) %if also on first col
                b = image(index-width);
                a = b;
                c = a_from_previous_line; %set c to previous 'a'
                a_from_previous_line = a; %update saved 'a'
                d = image((index-width)+1);
                
            elseif(0 == mod(index,width)) %if on last col
                a = image(index-1);
                b = image(index-width);
                c = image((index-width)-1);
                d = b;
            else
                a = image(index-1);
                b = image(index-width);
                c = image((index-width)-1);
                d = image((index-width)+1);
            end
        end
        
        % compute gradients
        g1 = d-b; g2 = b-c; g3 = c-a;
        %store in vector for computational purposes
        g_triplet = [g1,g2,g3];
        
        %% mode selection step 3
        if(g1 == g2 && g1 == g3 && g1 == near) 
            mode = 1; %go to run mode
            run_value = a; %very first sample in run
            run_count = 0;
        end
    end
    
    %% normal coding
    if(mode == 0)
        %% quantize g -> q step 4
        %get a quantized triplet
        q_triplet = zeros(1,3);
        for i = 1:3 %loop to quantize each gradient
            if(g_triplet(i) <= -T3)
                q_triplet(i) = -4;
            elseif(g_triplet(i) <= -T2)
                q_triplet(i) = -3;
            elseif(g_triplet(i) <= -T1)
                q_triplet(i) = -2;
            elseif(g_triplet(i) < near)
                q_triplet(i) = -1;
            elseif(g_triplet(i) == near)
                q_triplet(i) = 0;
            elseif(g_triplet(i) < T1)
                q_triplet(i) = 1;
            elseif(g_triplet(i) < T2)
                q_triplet(i) = 2;
            elseif(g_triplet(i) < T3)
                q_triplet(i) = 3;
            else
                q_triplet(i) = 4;
            end
        end
      
        %% compare triplet to map, get index and sign step 5
        for i=1:map_size
            if(isequal(context_map{i},q_triplet) > 0)
                sign = 0; %flip, all values in map start negative
                map_index = i; %refer to this index when correcting
                break %since map is 1 to 1, no need to continue
            elseif(isequal(context_map{i},-q_triplet) > 0)
                sign = 1; %dont flip, -q_triplet must be positive
                map_index = i; %refer to this index when correcting
                break %since map is 1 to 1, no need to continue
            else
                %do nothing
            end
        end
        
        
        
        %% compute prediction of sample x using edge detection step 6
        if(c >= max(a,b))
            predict_x = min(a,b);
        elseif(c <= min(a,b))
            predict_x = max(a,b);
        else
            predict_x = a+b-c;
        end
        
        %% adaptively correct prediction of x step 7
        if (sign == 1) %positive
            predict_x = predict_x + C(map_index);
        else %negative
            predict_x = predict_x - C(map_index);
        end
        if (predict_x > maxval) %clamp to max percision 
            predict_x = maxval;
        elseif (predict_x < 0) %clamp to min value
            predict_x = 0;
        end
        
        %% compute prediction residual (error value) step 8
        %force x to signed 8bit integer
        error_value = cast(x,'int16') - cast(predict_x,'int16');
        %flip sign to keep consistency
        if (sign == 0) %negative sign
            error_value = - error_value; %flip sign
        end
        
        %% mod reduce the prediction residual step 9
        if (error_value < 0)
            error_value = error_value + Range;
        end
        if (error_value >= ((Range+1)/ 2))
            error_value = error_value - Range;
        end
        
        %% compute the Golomb variable k step 10
        for k=0:8
            if bitsll(N(map_index),k)>=A(map_index)
                var_k = k; %set Golomb global to k
                break;
            end
        end
        
        %% map reduced error residual to non negative number step 11
        if (near == 0 && k == 0 && (2 * B(map_index)) <= (-N(map_index)))
            if error_value >= 0
                mapped_error_value = 2 * error_value + 1;
            else
                mapped_error_value = -2 * (error_value + 1);
            end
        else
            if error_value >= 0
                mapped_error_value = 2 * error_value;
            else
                mapped_error_value = -2 * error_value - 1;
            end
        end
        
        %% encode mapped reduced error residual to limited length code step 12
        %
        %this is only for matlab, since it works with integer..
        %convert to binary string, truncate by k and convert back to uint
        mErrVal_temp_bin = bitget(uint16(mapped_error_value),qbpp:-1:1,'uint16');%dec2bin(mapped_error_value,qbpp)
        %will need this value as well
        mErrVal_temp_bin_trunc = mErrVal_temp_bin(1:qbpp-k);
        %keep k lsb values, we'll need these for bitstream
        mErrVal_temp_bin_k_values = mErrVal_temp_bin(qbpp-k+1:qbpp);
        
        encoded_mapped_error_value_truncate = b2d(double(mErrVal_temp_bin_trunc));%bin2dec(mErrVal_temp_bin_trunc);

        %end matlab extra stuff
        %
        
        if encoded_mapped_error_value_truncate < (limit - qbpp - 1)
            %add number of zeros unary by that number
            for g = 1:encoded_mapped_error_value_truncate
                %append bitstream
                bitstream_index = bitstream_index + 1;
               %encoded_bitstream = strcat(encoded_bitstream,'0');
            end

            
            bitstream_index = bitstream_index + length(mErrVal_temp_bin_k_values)  + 1;
        else
            %else use this number of 0s
            for g = 1:(limit - qbpp - 1)
                %append bitstream
                bitstream_index = bitstream_index + 1;
            end

             if(exist('mErrVal_temp_bin_m1'))
                  bitstream_index = bitstream_index +  length(mErrVal_temp_bin_m1) + 1;
             else
                 bitstream_index = bitstream_index +  1; 
                 
             end
        end
        %% NOTE: everything below should be done at the end of the process
        %% update adaptive correction parameters step 13
        B(map_index) = B(map_index) + error_value *(2 *near + 1);
        A(map_index) = A(map_index) + abs(error_value);
        if (N(map_index) == reset)
            A(map_index) = bitsrl(cast(A(map_index),'uint8'),1);
            if (B(map_index) >= 0)
                B(map_index) = bitsrl(cast(B(map_index),'uint8'),1);
            else
                B(map_index) = -(bitsrl(cast(1-B(map_index),'uint8'),1));
            end
            N(map_index) = bitsrl(cast(N(map_index),'uint8'),1);
        end
        N(map_index) = N(map_index) + 1;
        
        %% do bias computation and clamp if needed step 14
        if (B(map_index) <= -N(map_index))
            B(map_index) = B(map_index) + N(map_index);
            if (C(map_index) > min_C)
                C(map_index) = C(map_index) - 1;
            end
            if (B(map_index) <= -N(map_index))
                B(map_index) = -N(map_index) + 1;
            end
        elseif (B(map_index) > 0)
            B(map_index) = B(map_index) - N(map_index);
            if (C(map_index) < max_C)
                C(map_index) = C(map_index) + 1;
            end
            if (B(map_index) > 0)
                B(map_index) = 0;
            end
        end             
    end
    
    %% run mode
    if(mode == 1)  %run mode
        %% run-length determination step 15
        if(x ~= run_value)
            mode = 2; %run coding
        end
        if(mode == 1) %dont count run interupt variable
        run_count = run_count + 1; %keep going, inc. count
        end
    end
    
    if(mod(index,width) == 0) %check EOL
        end_of_line = 1; %identify EOL
        
        if(mode == 1) %if just exited run counting
            mode = 2; %run coding
        end     
    else
        end_of_line = 0; %not EOL
    end
    
    %% run coding
    if(mode == 2) % run coding
        run_index = 1;
        
        %% encode run segments rg step 16
        %run for maximum lenght
        for j=1:run_count
            %else break when condition is met
            if(run_count < bitsll(1,J(run_index)))
                break;
            end
            %append a 1 to bitstream
            bitstream_index = bitstream_index + 1;
           % encoded_bitstream(bitstream_index) = 1;%encoded_bitstream = strcat(encoded_bitstream,'1');
            %dec. run_count by 1<<J
            run_count = run_count - bitsll(1,J(run_index));
            if(run_index < 32)
                run_index = run_index +1;
            end
        end
        %hold run_index before decrement *(see step 25)
        run_index_fixed = run_index;
        
        %if we were interupted by a change in value
        %% encode run segments lengths not rg step 17
        if(run_count > 0 || run_index == 1) %extra segments or run is 0
            if(end_of_line == 1)
                bitstream_index = bitstream_index + 1;
            else % x ~= run_value
                bitstream_index = bitstream_index + 1;
                temp_runcount_binary = bitget(uint16(run_count),J(run_index):-1:1,'uint16');%dec2bin(run_count,J(run_index));
                %decrement run index
                bitstream_index = bitstream_index + length(temp_runcount_binary);
                if (run_index > 1)
                    run_index = run_index - 1;
                end
            end
        end
        
        if(x ~= run_value) %only code run interupt sample if there is one
            %% compute index for run interupt sample step 18
            if(a == b)
                run_interupt_type = 1;
            else
                run_interupt_type = 0;
            end
            
            %% predict error for run interupt sample step 19
            if (run_interupt_type == 1)
                predict_x = a;
            else
                predict_x = b;
            end
            error_value = cast(x,'int16') - cast(predict_x,'int16');
            
            %% error computation (sign designation) step 20
            if ((run_interupt_type == 0) && (a > b))
                error_value = -error_value;
                sign = 0;
            else
                sign = 1;
            end
            
            %% compute aux temp variable for run step 21
            if (run_interupt_type == 0)
                temp_run_index = A(366);
            else
                temp_run_index = A(367) + bitsrl(cast(N(367),'uint8'),1);
            end
            %set map index accordingly to run_interupt_type + 366
            map_index = run_interupt_type + 366;
            
            %% compute k like in normal mode, use aux temp step 22
            for k=0:8
                if bitsll(N(map_index),k)>=temp_run_index
                    var_k = k; %set Golomb global to k
                    break;
                end
            end
            
            %% compute aux 'map' variable for error mapping step 23
            if ((k == 0) && (error_value > 0) && (2 * Nn(map_index) < N(map_index)))
                map = 1;
            elseif ((error_value < 0) && (2 * Nn(map_index) >= N(map_index)))
                map = 1;
            elseif ((error_value < 0) && (k ~= 0))
                map = 1;
            else
                map = 0;
            end
            
            %% error mapping complete for run interrupt sample step 24
            error_value = cast(error_value,'uint8');
            mapped_run_error_value = (2 * abs(error_value))-run_interupt_type - map;
            %% encode this run variable like normal mode step 25
            %
            %this is only for matlab, since it works with integer..
            %convert to binary string, truncate by k and convert back to uint
            mErrVal_temp_bin = bitget(uint16(mapped_run_error_value),qbpp:-1:1,'uint16'); %dec2bin(mapped_run_error_value,qbpp); f_d2b(mapped_run_error_value);
            %will need this value as well
            mErrVal_temp_bin_trunc = mErrVal_temp_bin(1:qbpp-k);
            %keep k lsb values, we'll need these for bitstream
            mErrVal_temp_bin_k_values = mErrVal_temp_bin(qbpp-k+1:qbpp);
            encoded_mapped_error_value_truncate = b2d(double(mErrVal_temp_bin_trunc));%bi2de(mErrVal_temp_bin_trunc,'left-msb'); f_b2d(mErrVal_temp_bin_trunc);
            %end matlab extra stuff
            %
            
            if encoded_mapped_error_value_truncate < ((limit - J(run_index_fixed) - 1) - qbpp - 1)
                %add number of zeros unary by that number
                for g = 1:encoded_mapped_error_value_truncate
                    %append bitstream
                     bitstream_index = bitstream_index + 1; %encoded_bitstream = strcat(encoded_bitstream,'0');
                end
                %append binary 1 after loop
               % encoded_bitstream(bitstream_index) = 1; %encoded_bitstream = strcat(encoded_bitstream,'1');
                bitstream_index = bitstream_index + 1;
                %lastly add k lsb values as they are to bitstream
                 bitstream_index = bitstream_index + length(mErrVal_temp_bin_k_values);
            else
                %else use this number of 0s
                for g = 1:(limit - qbpp - 1)
                    %append bitstream
                    bitstream_index = bitstream_index + 1;
                    %encoded_bitstream.push(0);%encoded_bitstream = strcat(encoded_bitstream,'0');
                end
                %append binary 1 after loop
                
               
                %append mapped_error_value-1 in binary to end
                mErrVal_temp_bin_m1 = bitget(uint16(mapped_run_error_value-1),qbpp:-1:1,'uint16'); %dec2bin(mapped_run_error_value-1,qbpp); f_d2b(mapped_run_error_value-1);
                bitstream_index = bitstream_index + length(mErrVal_temp_bin_m1) + 1;
            end
            
            %% update variables after run interrupt mapping step 26
            if (error_value < 0)
                Nn(map_index) = Nn(map_index) + 1;
            end
            A(map_index) = A(map_index) + bitsrl(cast((mapped_run_error_value + 1 - run_interupt_type),'uint8'),1);
            if (N(map_index) == reset)
                A(map_index) = bitsrl(cast(A(map_index),'uint8'),1);
                N(map_index) = bitsrl(cast(N(map_index),'uint8'),1);
                Nn(map_index) = bitsrl(cast(Nn(map_index),'uint8'),1);
            end
            N(map_index) = N(map_index) + 1;
            
            %done with run coding, go back to normal mode
            mode = 0;
        end
    end
  
end %end of code

final_CR = 100 * (bit_depth * width * height - bitstream_index)/(bit_depth * width * height);
fprintf('Final Compression Ratio = %.2f\n',final_CR);
out_textfile = fopen('GTs_four_fraction_bit_case_JPEG_LS_CRs.txt','a');
fprintf(out_textfile,'%.2f\n',final_CR);
end
fclose(out_textfile);	
