%calculates motion vectors based on luminance spectrum, then performs motion compensation
%ARGUMENTS: height, width, reference frame, current frame
function blocky = motion_est(height, width, ref, curr)
    p = 8; %search window size
    mb_wide = width/16; %num of macroblocks wide
    mb_tall = height/16; %num of macroblocks high
    
    %for storing motion vectors
    vectors_x = zeros(mb_tall, mb_wide);
    vectors_y = zeros(mb_tall, mb_tall);
    
    %for storing predicted frame
    blocky = uint8(zeros(height, width, 3));
    
    %obtain luminance spectra
    ref_lum = ref(:,:,1);
    curr_lum = curr(:,:,1);
    
    %perform motion estimation on each macroblock
    for block_row = 0: mb_tall-1
        for block_col = 0: mb_wide-1
            %defining/gridding macroblock pixel-boundaries
            mb_topedge = 1+(16*block_row);
            mb_botedge = 16+(16*block_row);
            mb_leftedge = 1+(16*block_col);
            mb_rightedge = 16+(16*block_col);
            
            %making macroblocks out of current frame's luminance matrix
            mblock = curr_lum(mb_topedge:mb_botedge, mb_leftedge:mb_rightedge);
                
            %determining search window pixel-boundaries:
            %...corner cases
            if (block_row == 0 && block_col == 0) %top left
                window = ref_lum(1:16+p, 1:16+p);
            elseif (block_row == 0 && block_col == mb_wide-1) %top right
                window = ref_lum(1:16+p, width-(15+p):width);
            elseif (block_row == mb_tall-1 && block_col == 0) %bottom left
                window = ref_lum(height-(15+p):height, 1:16+p);
            elseif (block_row == mb_tall-1 && block_col == mb_wide-1) %bottom right
                window = ref_lum(height-(15+p):height, width-(15+p):width);
            
            %...edge cases
            elseif (block_row == 0) %top
                window = ref_lum(1:16+p, mb_leftedge-p:mb_rightedge+p);
            elseif (block_row == mb_tall-1) %bottom
                window = ref_lum(height-(15+p):height, mb_leftedge-p:mb_rightedge+p);
            elseif (block_col == 0) %left
                window = ref_lum(mb_topedge-p:mb_botedge+p, 1:16+p);
            elseif (block_col == mb_wide-1) %right
                window = ref_lum(mb_topedge-p:mb_botedge+p, width-(15+p):width);
                
            %...default/middle case
            else window = ref_lum(mb_topedge-p:mb_botedge+p, mb_leftedge-p:mb_rightedge+p);
            end
                
            %search init
            diff_init = abs(mblock - window(1:16, 1:16)); %first possible search
            best_SAD = sum(sum(diff_init)); %SAD of first search
            
            %search all possibilities (exhaustive)
            for win_pixrow = 1: size(window,1)-15
                for win_pixcol = 1: size(window,2)-15
                    compare_block = window(win_pixrow:win_pixrow+15, win_pixcol:win_pixcol+15);
                    diff = abs(mblock - compare_block);
                    SAD = sum(sum(diff));
                        
                    %compare with previous searches
                    if (SAD < best_SAD)
                        best_SAD = SAD;
                        
                        %vertical vector component
                        if (block_row == 0) %if search window is clipped at top edge
                            vectors_y(block_row+1, block_col+1) = win_pixrow-1;
                        else vectors_y(block_row+1, block_col+1) = (win_pixrow-1) - p;
                        end
                        
                        %horizontal vector component
                        if (block_col == 0) %if search window is clipped at left edge
                            vectors_x(block_row+1, block_col+1) = win_pixcol-1;
                        else vectors_x(block_row+1, block_col+1) = (win_pixcol-1) - p;
                        end
                    end   
                end
            end
        end
    end
    
    %assemble the motion predicted frame using the vectors
    for block_j = 0: mb_tall-1
        for block_i = 0: mb_wide-1
            blocky(1+(block_j*16):16+(block_j*16), 1+(block_i*16):16+(block_i*16), :) = ...
            ref((1+(block_j*16):16+(block_j*16)) + vectors_y(block_j+1, block_i+1), ...
            (1+(block_i*16):16+(block_i*16)) + vectors_x(block_j+1, block_i+1), :);
        end
    end
    
    %motion vector plot
    %
    figure, quiver(repmat(1:16:width, mb_tall, 1), -repmat((1:16:height)', 1, mb_wide), ...
        vectors_x(1:mb_tall, 1:mb_wide), -vectors_y(1:mb_tall, 1:mb_wide));
    %
end