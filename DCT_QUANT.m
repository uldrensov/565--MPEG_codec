%performs DCT and quantisation, and their inverses
%ARGUMENTS: height, width, RGB frame
function frame = DCT_QUANT(height, width, frame)
    %constant quantisation matrix
    Q = 28*ones(8,8);
    
    %YCbCr conversion
    frame = rgb2ycbcr(frame);
    
    %DCT of each spectrum
    Y = blkproc(frame(:,:,1), [8 8], @dct2);
    Cb = blkproc(frame(:,:,2), [8 8], @dct2);
    Cr = blkproc(frame(:,:,3), [8 8], @dct2);
    
    %quantisation and inverse quantisation
    for i = 1:8: height-7
        for j = 1:8: width-7
            Y(i:i+7, j:j+7) = fix(Y(i:i+7, j:j+7) ./ Q);
            Y(i:i+7, j:j+7) = Y(i:i+7, j:j+7) .* Q;
            
            Cb(i:i+7, j:j+7) = fix(Cb(i:i+7, j:j+7) ./ Q);
            Cb(i:i+7, j:j+7) = Cb(i:i+7, j:j+7) .* Q;
            
            Cr(i:i+7, j:j+7) = fix(Cr(i:i+7, j:j+7) ./ Q);
            Cr(i:i+7, j:j+7) = Cr(i:i+7, j:j+7) .* Q;
        end
    end
    
    %inverse DCT
    Y = blkproc(Y,[8 8],@idct2);
    Cb = blkproc(Cb,[8 8],@idct2);
    Cr = blkproc(Cr,[8 8],@idct2);
    
    %reattach the component spectra and convert back to RGB
    frame(:,:,1) = Y;
    frame(:,:,2) = Cb;
    frame(:,:,3) = Cr;
    frame = ycbcr2rgb(frame);
end