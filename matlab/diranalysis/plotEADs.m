function plotEADs( Azimuth,Energy,Diffuseness )
% Plot variables
figure; imagesc(log(Energy)); title('Energy');set(gca,'YDir','normal')
xlabel('Time frame'); ylabel('Freq bin');
figure; imagesc(Azimuth);colorbar; set(gca,'YDir','normal')
title('Azimuth'); xlabel('Time frame'); ylabel('Freq bin');
figure; imagesc(Diffuseness);colorbar; set(gca,'YDir','normal')
title('Diffuseness'); xlabel('Time frame'); ylabel('Freq bin');
end
