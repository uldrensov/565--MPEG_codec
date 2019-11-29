function void = hw_565_4()
%STEP 0: INIT
    %read video and get its specs/stats
    vid = VideoReader('football_qcif.avi');
    vid_info = get(vid);
    
    %find timestamps for frames 7-11
    frame_nums = 7:11;
    timestamps = (frame_nums-1)/vid_info.FrameRate;
    
    %for storing PSNR
    frame_PSNR = zeros(1,5);
    
    
%STEP 1: I-FRAME
    %set video time for the timestamp of the I-frame, then perform 4:2:0
    vid.CurrentTime = timestamps(1);
    orig_fram = readFrame(vid);
    ifram = chroma_subsamp_420(vid_info.Height, vid_info.Width, orig_fram);
    
    %perform DCT, quantisation, inv. quantisation, and IDCT on I-frame
    ifram = DCT_QUANT(vid_info.Height, vid_info.Width, ifram);
    
    %calculate PSNR
    frame_PSNR(1) = psnr(ifram, orig_fram, 255);
    fprintf("PSNR(I-frame): %d\n", frame_PSNR(1));
    
    %store I-frame as reference for the next frame
    ref = ifram;
    figure, imshow(ifram);
       
    
%STEP 2: P-FRAME 1
    %fetch raw p-frames, then combine all frames into one "array"
    album = cat(4,ifram); %4D array
    for n=2:5
        vid.CurrentTime = timestamps(n);
        p = readFrame(vid);
        album(:,:,:,n) = p;
    end
    
    %perform 4:2:0 on the first P-frame
    orig_fram = album(:,:,:,2);
    curr = chroma_subsamp_420(vid_info.Height, vid_info.Width, orig_fram);
    
    %perform motion estimation between current and reference frames
    blocky = motion_est(vid_info.Height, vid_info.Width, ref, curr);
    
    %produce residual frame and perform DCT/quantisation on it
    residuals = zeros(vid_info.Height, vid_info.Width, 3, 4);
    residuals(:,:,:,1) = double(curr) - double(blocky);
    residuals(:,:,:,1) = DCT_QUANT(vid_info.Height, vid_info.Width, residuals(:,:,:,1));
    figure, imshow(residuals(:,:,:,1));
    
    %reconstruct the P-frame and replace its raw counterpart in the album
    album(:,:,:,2) = uint8(double(blocky) + residuals(:,:,:,1));
    
    %calculate PSNR
    frame_PSNR(2) = psnr(album(:,:,:,2), orig_fram, 255);
    fprintf("PSNR(P-frame #1): %d\n", frame_PSNR(2));
    figure, imshow(album(:,:,:,2));
    
    
%STEP 3: P-FRAMES 2-4
    %loop through the above process now that the I-frame is no longer needed
    for n=3:5
        %retrieve previously reconstructed frame as the new reference frame
        %ref = album(:,:,:,n-1);
        
        %perform 4:2:0 on current frame
        orig_fram = album(:,:,:,n);
        curr = chroma_subsamp_420(vid_info.Height, vid_info.Width, orig_fram);
        
        %perform motion estimation
        blocky = motion_est(vid_info.Height, vid_info.Width, ref, curr);
        
        %produce and DCT/quantise residual frame
        residuals(:,:,:,n-1) = double(curr) - double(blocky);
        residuals(:,:,:,n-1) = DCT_QUANT(vid_info.Height, vid_info.Width, residuals(:,:,:,n-1));
        figure, imshow(residuals(:,:,:,n-1));
        
        %reconstruct and replace P-frame
        album(:,:,:,n) = uint8(double(blocky) + residuals(:,:,:,n-1));
        
        %PSNR
        frame_PSNR(n) = psnr(album(:,:,:,n), orig_fram, 255);
        fprintf("PSNR(P-frame #%d): %d\n", n-1, frame_PSNR(n));
        figure, imshow(album(:,:,:,n));
    end
    
    %average PSNR for all frames involved
    fprintf("AVERAGE: %d\n", sum(frame_PSNR)/5);
end

%MSE for reconst frames?
%show vectors too?

%error frame + Ycomp of motion est = reconst???
%Ycomp of 420 used with Iframe for mocomp