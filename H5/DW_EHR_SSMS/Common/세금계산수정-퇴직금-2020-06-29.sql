USE [dwehrdev_H5]
GO
; 86 line float -> numeric���� ����
      DECLARE @n_b1_work_mm           NUMERIC(2)        -- �ټӿ���    
      DECLARE @n_bc1_dup_mm           NUMERIC(2)        -- �ߺ�����    

F_REP_R04_DEDUCT���� 42 Line
        --SET @n_r04_deduct = dbo.XF_CEIL(@n_deduct_mon + ((@an_r04_n_12 - dbo.XF_GREATEST_N((@n_sta_mon-1),0,0,0)) * @n_deduct_rate/100), 0);
		SET @n_r04_deduct = dbo.XF_TRUNC_N(@n_deduct_mon + ((@an_r04_n_12 - dbo.XF_GREATEST_N((@n_sta_mon-1),0,0,0)) * @n_deduct_rate/100), 0);
;
P_REP_CAL_TAX���� 1099 Line
                        --SET @n_rep_calc_R06_N = dbo.XF_TRUNC_N(@n_rep_calc_R05_12 / 12, 0) * @n_bc1_work_yy
                        SET @n_rep_calc_R06_N = dbo.XF_TRUNC_N(@n_rep_calc_R05_12 / 12 * @n_bc1_work_yy, 0)