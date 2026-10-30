
load('psnrs_filtered_averages.mat');
load('psnrs_unfiltered_averages.mat');
load('psnrs_gts_averages.mat');

Q = [1,2,4,8,16,32,64];
plot(Q,psnrs_unfiltered_averages,'-O');
%title('Test Plots')
%xlim(Q,[0 64])
hold on
plot(Q,psnrs_filtered_averages,'-O');
hold off
hold on
plot(Q,psnrs_gts_averages,'-O');
hold off
%set(gca,'XLim',[0 65]);
xticks(Q)
xticklabels({'1','2','4','8','16','32','64'})
xlabel('Quantization Factor (Q)') 
ylabel('PSNR (dB)')
legend({'Unfiltered DMs','Median Filtered DMs','Ground Truth DMs'},'FontSize',14);
set(gca,'FontWeight','bold')