%% build jpeg container
function JPEG_CONTAINER_BITS = JPEG_CONTAINER(image)
[height,width] = size(image);
%keep these
SOI = 65496; %start of image
SOF = 65527; %stat of jls frame
marker_SOF = 11; %length of sof marker
SOS = 65498; %start of scan marker
marker_SOS = 8; %length of SOS marker
EOI = 65497; %end of image

%variable
P = 8; %init precision
Y = height; %init number of lines
X = width; %init number of cols
Nf = 1; %init number of components
C1 = 1; %init component ID
H1 = 1; V1 = 1; %init subsampling per comp.
Tq1 = 0; %KEEP ZERO
Ns = 1; %init number of components
Ci = 1; %init component ID
Tm1 = 0; %init mapping table index
near = 0; %init loss/lossless
ILV = 0; %init interleave mode
Al = 0; Ah = 0; %init point transform

jpeg_header = char.empty;

%populate header
temp_b = dec2bin(SOI,16);
jpeg_header = strcat(jpeg_header,temp_b);
temp_b = dec2bin(SOF,16);
jpeg_header = strcat(jpeg_header,temp_b);
temp_b = dec2bin(marker_SOF,16);
jpeg_header = strcat(jpeg_header,temp_b);
temp_b = dec2bin(P,8);
jpeg_header = strcat(jpeg_header,temp_b);
temp_b = dec2bin(Y,16);
jpeg_header = strcat(jpeg_header,temp_b);
temp_b = dec2bin(X,16);
jpeg_header = strcat(jpeg_header,temp_b);
temp_b = dec2bin(Nf,8);
jpeg_header = strcat(jpeg_header,temp_b);
temp_b = dec2bin(C1,8);
jpeg_header = strcat(jpeg_header,temp_b);
temp_b = dec2bin(H1,4);
jpeg_header = strcat(jpeg_header,temp_b);
temp_b = dec2bin(V1,4);
jpeg_header = strcat(jpeg_header,temp_b);
temp_b = dec2bin(Tq1,8);
jpeg_header = strcat(jpeg_header,temp_b);

temp_b = dec2bin(SOS,16);
jpeg_header = strcat(jpeg_header,temp_b);
temp_b = dec2bin(marker_SOS,16);
jpeg_header = strcat(jpeg_header,temp_b);
temp_b = dec2bin(Ns,8);
jpeg_header = strcat(jpeg_header,temp_b);
temp_b = dec2bin(Ci,8);
jpeg_header = strcat(jpeg_header,temp_b);
temp_b = dec2bin(Tm1,8);
jpeg_header = strcat(jpeg_header,temp_b);
temp_b = dec2bin(near,8);
jpeg_header = strcat(jpeg_header,temp_b);
temp_b = dec2bin(ILV,8);
jpeg_header = strcat(jpeg_header,temp_b);
temp_b = dec2bin(Al,4);
jpeg_header = strcat(jpeg_header,temp_b);
temp_b = dec2bin(Ah,4);
jpeg_header = strcat(jpeg_header,temp_b);
%add EOI marker
temp_b = dec2bin(EOI,16);
JPEG_CONTAINER_BITS = length(jpeg_header) + length(temp_b);
end