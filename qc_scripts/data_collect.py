import os
import pandas as pd


def data_collect(data_list, output):
    nonpvc_gm = {}
    pvc_gm = {}
    try:
        for sub in data_list:
            if 'sub-' not in sub: continue
            group_dir_path = r'/gpfs01/imgshare/TILDA/test_pipeline/DATA'
            dir_path = os.path.join(group_dir_path, sub)
            roi_path = os.path.join(dir_path, 'oxasl_vol_50gm_pv', 'native', 'roi_stats.csv')
            roi_gm_path = os.path.join(dir_path, 'oxasl_vol_50gm_pv', 'native', 'roi_stats_gm.csv')
            roi_wm_path = os.path.join(dir_path, 'oxasl_vol_50gm_pv', 'native', 'roi_stats_wm.csv')

            perfusion_df = pd.read_csv(roi_path)
            perfusion_gm_df = pd.read_csv(roi_gm_path)
            perfusion_wm_df = pd.read_csv(roi_wm_path)

            roi_names = ['50%+GM', '90%+WM', 'Right_Cerebral_White_Matter_80%+',
                         'Left_Cerebral_White_Matter_80%+', 'VBA', 'RICA', 'LICA']
            roi_gm_names = ['80%+GM', 'VBA', 'RICA', 'LICA']
            roi_wm_names = ['90%+WM', 'Right_Cerebral_White_Matter_80%+', 'Left_Cerebral_White_Matter_80%+']

            roi_indices = perfusion_df.index[perfusion_df['name'].isin(roi_names)].tolist()
            roi_gm_indices = perfusion_gm_df.index[perfusion_gm_df['name'].isin(roi_gm_names)].tolist()
            roi_wm_indices = perfusion_wm_df.index[perfusion_wm_df['name'].isin(roi_wm_names)].tolist()

            roi_stats_df = perfusion_df.iloc[roi_indices].reset_index(drop=True)
            roi_gm_stats_df = perfusion_gm_df.iloc[roi_gm_indices]
            roi_wm_stats_df = perfusion_wm_df.iloc[roi_wm_indices]
            roi_pvc_stats_df = pd.concat([roi_gm_stats_df, roi_wm_stats_df], axis=0).reset_index(drop=True)
            # roi_pvc_stats_df = roi_pvc_stats_df.reset_index(drop=True)

            roi_stats = {}
            roi_stats['nonpvc'] = roi_stats_df
            roi_stats['pvc'] = roi_pvc_stats_df

            for perf in roi_stats.values():
                perf['SpCov'] = perf[['Std', 'Mean']].apply(lambda x: x['Std'] * 100 / x['Mean'], axis=1).round(2)

            nonpvc_gm[sub] = perfusion_df[perfusion_df['name'] == '50%+GM']['Mean'].to_numpy()
            pvc_gm[sub] = perfusion_gm_df[perfusion_gm_df['name'] == '80%+GM'][ 'Mean'].to_numpy()

    except Exception as e:
        print(e)

    t = pd.DataFrame.from_dict(nonpvc_gm, orient='index')# concat(nonpvc_sum, axis=0).reset_index(drop=True)
    t. to_csv(os.path.join(output, 'nonpvc_50pv.csv'))
    print(t.head(5))

    #t = pd.DataFrame.from_dict(pvc_gm, orient='index')  # concat(nonpvc_sum, axis=0).reset_index(drop=True)
    #t.to_csv(os.path.join(output, 'pvc_80pv.csv'))
    #return nonpvc_sum, pvc_sum



if __name__ == '__main__':

    group_dir_path = r'/gpfs01/imgshare/TILDA/test_pipeline/DATA'
    dir_list = os.listdir(group_dir_path)
    dir_path_list = [os.path.join(group_dir_path, f) for f in dir_list if 'sub-'  in f]
    #path = r'/gpfs01/imgshare/TILDA/test_pipeline/DATA/sub-1267032/oxasl_vol_50gm_pv/native' #roi_stats.csv roi_stats_gm.csv roi_stats_wm.csv
    output = r'/gpfs01/imgshare/TILDA/test_pipeline/scripts/ASL_QC_package'
    data_collect(dir_list, output)
