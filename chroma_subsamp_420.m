%performs 4:2:0 chroma subsampling, then upsamples via replication method
%ARGUMENTS: height, width, RGB frame
function frame = chroma_subsamp_420(height, width, frame)
    %rows and cols to delete
    row_del = 2:2:height;
    col_del = 2:2:width;
    
    %YCbCr conversion
    frame = rgb2ycbcr(frame);
    
    %row/col deletion
    frame(row_del, :, 2:3) = nan;
    frame(:, col_del, 2:3) = nan;
    
    %row/col reconstruction
    frame(row_del, :, 2:3) = frame(row_del-1, :, 2:3);
    frame(:, col_del, 2:3) = frame(:, col_del-1, 2:3);
end