%% constants
targetHeight = 1024;% H'
targetWidth = 1024;% W'
gridNumOfRows = 25;% M
gridNumOfCols = 25;% N

%% read image
image = imread('Desert.jpg');
[imageHeight, imageWidth, rgb] = size(image);% [H W]

percentage = 0.2;
minGridHeight = percentage * imageHeight/gridNumOfRows;% Lh
minGridWidth = percentage * imageWidth/gridNumOfCols;% Lw
assert(targetHeight/gridNumOfRows >= minGridHeight);
assert(targetWidth/gridNumOfCols >= minGridWidth);

%% convert image to grayscale
grayImage = rgb2gray(image);
%imshow(grayImage);
%hold on

%% create the saliency image using sobel kernel
saliencyImage = imfilter(grayImage,fspecial('sobel'));
figure, imshow(saliencyImage);

%% dilation operation
R = 4;
N = 4;
SE = strel('disk', R, N);
saliencyImage = imdilate(saliencyImage,SE);
resizedSaliencyImage = imresize(saliencyImage, [gridNumOfRows gridNumOfCols]);
% resizing instead of calculating average
figure, imshow(saliencyImage);

%% calculate average saliency
saliencyMap = zeros(gridNumOfRows,gridNumOfCols);
rowHeight = imageHeight/gridNumOfRows;
colWidth = imageWidth/gridNumOfCols;
for i=1:gridNumOfRows
    for j=1:gridNumOfCols
        startRow = floor((i-1)*rowHeight) + 1;
        endRow = ceil(i*rowHeight);
        startCol = floor((j-1)*colWidth) + 1;
        endCol = ceil(j*colWidth);
        saliencyMap(i,j) = mean2(saliencyImage(startRow:endRow , startCol:endCol));
    end
end
saliencyMap = saliencyMap./255;
%figure, imshow(saliencyMap)

%% ASAP energy
K = zeros(gridNumOfRows * gridNumOfCols, gridNumOfRows + gridNumOfCols);

for k=1:size(K,1)
    for l=1:size(K,2)
        r = ceil(k/gridNumOfCols);
        c = mod(k - 1, gridNumOfCols) + 1;
        
        if l==r
            K(k,l) = saliencyMap(r,c) * (gridNumOfRows / imageHeight);
        elseif l==(gridNumOfRows + c)
            K(k,l) = -saliencyMap(r,c) * (gridNumOfCols / imageWidth);
        else
            K(k,l) = 0;
        end
    end
end

Q = K' * K;
b = zeros(gridNumOfRows + gridNumOfCols, 1);

%% solve the QP problem
cvx_begin
variable sRows(gridNumOfRows) nonnegative;
variable sCols(gridNumOfCols) nonnegative;
s = [sRows; sCols];

minimize (s' * Q * s + s' * b)

subject to
sRows >= minGridHeight;
sCols >= minGridWidth;
sum(sRows) == targetHeight;
sum(sCols) == targetWidth;
cvx_end

%% Image resizing and deformation
sRows_rounded = round(sRows);
sCols_rounded = round(sCols);
s_rounded = round(s);

for j=1:gridNumOfCols
    startCol = floor((j-1)*colWidth) + 1;
    endCol = ceil(j*colWidth);
    if j==1
        q = imresize(image(: , startCol:endCol , : ) , [size(image,1) , sCols_rounded(j)]);
        continue;
    end
    q = [q , imresize(image(: , startCol:endCol , :) , [size(image,1) , sCols_rounded(j)])];
end

for i=1:gridNumOfRows
    startRow = floor((i-1)*rowHeight) + 1;
    endRow = ceil(i*rowHeight);
    if i==1
        deformated_image = imresize(q(startRow:endRow , : , :) , [sRows_rounded(i) , size(q,2)]);
        continue;
    end
    deformated_image = [deformated_image ; imresize(q(startRow:endRow , : , :) , [sRows_rounded(i) , size(q,2)])];
end

%% show the final result
figure, imshow(deformated_image);



