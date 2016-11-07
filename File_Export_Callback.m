
function File_Export_Callback(hObject, eventdata, handles)

%############################
%NEED TO ADD CHECK THAT ANALyZED DATA IS AVAILABLE GREY OUT OPTION IN GUI
% COULD ALSO ADD SOME SUMMARY STATS HERE.
%############################

% Function to write all filopodia data in struct handles to a file
% Cannot use XLSWRITE - not supported on Mac OS X!

% prompt for file location
[file,path] = uiputfile('Results.csv', 'Save Results As')

if file ~= 0 % if uiputfile returns SOMETHING.
    %Open the file with write permission (overwrites existing) 
    fid = fopen(fullfile(path, file), 'w');
   
    %Build the results header. 
    fprintf(fid, '%s\n', '#########################################################');
    fprintf(fid, '%s\n', 'MyWay Filopodia Colocalization Analysis');
    fprintf(fid, '%s %s\n', 'Version', num2str(handles.globals.CODE_VERSION));
    fprintf(fid, '%s\n', 'J.Bird - Laboratory of Molecular Genetics - NIDCD/NIH');
    fprintf(fid, '%s %s\n', 'Results generated', datestr(now)); 
    fprintf(fid, '%s\n', '#########################################################');
    fprintf(fid, '%s\n', 'Analysis Parameters');
    fprintf(fid, 'ALIGN_WINDOW [%2.1f %2.1f]\nMEAN_WINDOW [%2.1f %2.1f]\nSD %2.1f\n', handles.globals.ALIGN_WINDOW(1), handles.globals.ALIGN_WINDOW(2), handles.globals.MEAN_WINDOW(1), handles.globals.MEAN_WINDOW(2), handles.globals.SD);
    fprintf(fid, 'BLOCK_SIZE %2.2f\nBLOCK_TRIALS %u\nPERCENTILE %2.2f\nPREY_WOBBLE %2.2f\nFWHM %2.2f\n', handles.globals.BLOCK_SIZE, handles.globals.BLOCK_TRIALS, handles.globals.PERCENTILE, handles.globals.PREY_WOBBLE, handles.globals.FWHM);  
    fprintf(fid, 'CORR_TYPE %s\nINTERACTION_MODE %s\nDATA_FORMAT %s\n', handles.globals.CORR_TYPE.mode, handles.globals.INTERACTION_MODE.mode, handles.globals.DATA_FORMAT.mode);
    fprintf(fid, '\n%s\n', '#########################################################');
    fprintf(fid, '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n', 'Filopodia #', 'File','ID','Bait Threshold','Prey Threshold',...
       'Bait Significant?','Prey Significant?', 'Max XCorr', 'R', 'R P-value', ...
       'R Significant?', 'OVERALL INTERACTION?', 'RAW BAIT MAX', 'RAW PREY MAX');
  
    %Now loop through the handles.data struct and fprintf to fid.
    %Also accumulate some summary statistics whilst looping through.
    
    bait_positive = 0;
    interaction = 0;
    ratio = 0;
    
    [~,filopodia_max,~] = size(handles.data);
    filopodia = 1; 
    
    while filopodia <= filopodia_max
        %ONLY print data IF data.Include flag is set
        if handles.data(filopodia).Include == 1
            fprintf(fid, '%u,%s,%u,%5.2f,%5.2f,%u,%u,%5.2f,%5.2f,%5.2f,%u,%u, %5.2f, %5.2f\n', filopodia, handles.data(filopodia).Filename, handles.data(filopodia).FilopodiaID,...
                handles.data(filopodia).Bait_Threshold, handles.data(filopodia).Prey_Threshold, handles.data(filopodia).Bait_Positive, handles.data(filopodia).Prey_Positive, ...
            handles.data(filopodia).Max_XCorr, handles.data(filopodia).Rho, handles.data(filopodia).Rho_pval, ...
            handles.data(filopodia).Rho_interact, handles.data(filopodia).Consensus_interact,...
            handles.data(filopodia).Max_Bait_Raw, handles.data(filopodia).Max_Prey_Raw);
        
            bait_positive = bait_positive + handles.data(filopodia).Bait_Positive;
            interaction = interaction + handles.data(filopodia).Consensus_interact;
        end
        
        filopodia = filopodia + 1;    
    end
    
    ratio = interaction / bait_positive;
    
    fprintf(fid, '\n\n%s,%u,\n%s,%u', 'Interacting filopodia', interaction, 'Total Filopodia', bait_positive);
    fprintf(fid, '\n%s,%4.2f', 'Interaction Index', ratio);  
    fprintf(fid, '\n\nEND');

    %Close file handle 
    fclose(fid);
       
end


end


