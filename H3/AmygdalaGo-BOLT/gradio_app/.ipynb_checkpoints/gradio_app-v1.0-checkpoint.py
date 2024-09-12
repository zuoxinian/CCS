import numpy as np
import nibabel as nib
import gradio as gr
import json
import os
import copy
import cv2
import sys
from flask import Flask, request
from datetime import datetime
sys.path.append('/root/autodl-tmp/v1.1/')
import time
import inference_zcyy
import math

def normalization(data):
    _range = np.max(data) - np.min(data)
    return (data - np.min(data)) / _range

def merge_img_seg_v2(img, mask):
#     print(img.shape, mask.shape, img.max(), img.min(), mask.max(), mask.min())
    overlay = mask * 0.5 + img * 0.5
    return img, mask, overlay
    

def merge_img_seg_v2_new(img, mask):
    img = np.expand_dims(img, axis=2)
    img = np.concatenate((img, img, img), axis=-1)
    mask_new = mask
    mask = np.expand_dims(mask, axis=2)
    mask = np.concatenate((mask, mask, mask), axis=-1)
    img_new = img
    img = img[:, :, ::-1]
    img[..., 2] = np.where(mask_new == 1, 255, img[..., 2])
    img = normalization(img)
    img = img * 2 - 1
    return img_new, mask, img

def merge_img_seg_v1(img, mask):
    img = np.expand_dims(img, axis=2)
    img = np.concatenate((img, img, img), axis=-1)
    img_new = img
    mask_new = mask
    
    mask = normalization(mask)
    mask = np.array(mask, np.uint8)
    contours, _ = cv2.findContours(mask, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
    cv2.drawContours(img.copy(), contours, -1, (0, 0, 255), 1)

    img = img[:, :, ::-1]
    img[..., 2] = np.where(mask == 1, 255, img[..., 2])
    
    mask = np.expand_dims(mask_new, axis=2)
    mask = np.concatenate((mask, mask, mask), axis=-1)
    img = normalization(img)
    
    return img_new.astype(np.float32), mask.astype(np.float32), img.astype(np.float32)
    
class Backstage:
    def __init__(self) -> None:
        self.parameter_map = {}
        self.fn = None
        self.output_arr:np.ndarray = None
        self.input_arr:np.ndarray = None
        
    def setting_parameters(self, key, value):
        self.parameter_map[key] = value

    def out_json(self):
        with open("./parameter.json", 'w') as file:
            json.dump(self.parameter_map, file)

    def read_json(self):
        data = None
        with open('./label.json', 'r') as json_file:
            data = json.load(json_file)
        print("json ========={}".format(data))
        return data
    
    def success(self):
        return 'Run successfully!'
        
    def save(self): 
        # global minlay
        nifti_image = nib.Nifti1Image(minlay.new_data, affine=np.eye(4))
        minlay.select_flag = False
        print("output_file: {}".format(minlay.file_name))
        nib.save(nifti_image, minlay.file_name)
        print("file_name ========= {}".format(minlay.file_name))
        return minlay.file_name
    
# app = Flask(__name__)
# @app.route('/')
# def get_client_ip():
#     # 使用 request.remote_addr 获取客户端的IP地址
#     client_ip = request.remote_addr
#     print('Client IP Address: {}'.format(client_ip))
#     return f'Client IP Address: {client_ip}'


class MiddleLayer:
    def __init__(self) -> None:
        self.new_data = None
        self.old_data = None
        self.select_flag = False
        self.file_name = None
        self.file_extension = None
        self.left, self.right = 0, 0
        
        self.json_file_path = "./unit/unit.json"

        # 检查文件是否存在
        if os.path.exists(self.json_file_path):
            # 如果文件存在，读取JSON数据
            with open(self.json_file_path, 'r') as file:
                ip_data = json.load(file)
            print("已读取 JSON 文件内容:", ip_data)
        else:
            # 如果文件不存在，创建一个空的JSON数据
            ip_data = {}
            print("JSON 文件不存在，创建一个空的JSON数据.")

            # 将空的JSON数据写入文件
            with open(self.json_file_path, 'w') as file:
                json.dump(ip_data, file)
            print("已创建并写入空的 JSON 文件:", self.json_file_path)
        
    def read_nii(self, nii_obj):

        img = nib.load(nii_obj.name)
        path = nii_obj.name
        print("path ===== {}".format(str(nii_obj.name)))
        self.file_name, self.file_extension = os.path.splitext(os.path.basename(path))
        self.file_name = "./output/AmygdalaGo-BOLT_seg_" + self.file_name +  self.file_extension    
        self.old_data = img.get_fdata()
    
    def get_time(self):
        # 获取当前日期和时间
        current_datetime = datetime.now()
        # print("当前日期和时间:", current_datetime)

        # 获取当前日期
        current_date = datetime.now().date()
        # print("当前日期:", current_date)

        # 获取当前时间
        current_time = datetime.now().time()
        # print("当前时间:", current_time)

        # 格式化输出日期和时间
        # formatted_datetime = current_datetime.strftime("%Y-%m-%d %H:%M:%S")
        return current_datetime.strftime("%Y-%m-%d %H:%M:%S")
    
    def read_nii_select(self, path_):
        img = nib.load(path_)
        self.file_name, self.file_extension = os.path.splitext(os.path.basename(path_))
        self.file_name = "./output/AmygdalaGo-BOLT_seg_" + self.file_name +  self.file_extension    
        self.old_data = img.get_fdata()

    def get_nii_array_list_xy(self, nii_array):
        _, _, z = nii_array.shape
        imglist = []
        for i in range(0, z):
            img_arr = nii_array[:, :, i]
            img_arr = (img_arr - np.min(img_arr)) / (np.max(img_arr) - np.min(img_arr))
            imglist.append(img_arr)
        return imglist

    def get_nii_array_list_xz(self, nii_array):
        _, y, _ = nii_array.shape
        imglist = []
        for i in range(0, y):
            img_arr = nii_array[:, i, :]
            img_arr = (img_arr - np.min(img_arr)) / (np.max(img_arr) - np.min(img_arr))
            imglist.append(img_arr)
        return imglist

    def get_nii_array_list_yz(self, nii_array):
        x, _, _ = nii_array.shape
        imglist = []
        for i in range(0, x):
            img_arr = nii_array[i, :, :]
            img_arr = (img_arr - np.min(img_arr)) / (np.max(img_arr) - np.min(img_arr))
            imglist.append(img_arr)
        return imglist

    def get_xy(self):
        return self.get_nii_array_list_xy(minlay.old_data)

    def get_xz(self):
        return self.get_nii_array_list_xz(minlay.old_data)

    def get_yz(self):
        return self.get_nii_array_list_yz(minlay.old_data)

    ##################################################################
    def get_xy_test(self):
        return self.get_nii_array_list_xy(minlay.new_data)

    def get_xz_test(self):
        return self.get_nii_array_list_xz(minlay.new_data)

    def get_yz_test(self):
        return self.get_nii_array_list_yz(minlay.new_data)
    #################################################################
    

    
    def merge_xy(this):
        minlay.select_flag = False
        xy_old = this.get_xy()
        this.xy_new = this.get_xy_test()
        
        
        xy_merge_list = []
        for i in range(0, len(xy_old)):
            if np.sum(this.xy_new[int(i)]) > 0:
                
                temp = np.rot90((np.concatenate((merge_img_seg_v2(xy_old[int(i)], this.xy_new[int(i)])))))
                xy_merge_list.append(temp)
        
        return xy_merge_list
    
    def merge_xz(this):
        minlay.select_flag = False
        xy_old = this.get_xz()
        this.xz_new = this.get_xz_test()
        xy_merge_list = []

        for i in range(0, len(xy_old)):
            if np.sum(this.xz_new[int(i)]) > 0:
                temp = np.rot90((np.concatenate((merge_img_seg_v2(xy_old[int(i)], this.xz_new[int(i)])))))
                xy_merge_list.append(temp)
        return xy_merge_list
    
    def merge_yz(this):
        minlay.select_flag = False
        xy_old = this.get_yz()
        this.yz_new = this.get_yz_test()
        
        xy_merge_list = []

        for i in range(0, len(xy_old)):
            if np.sum(this.yz_new[int(i)]) > 0:
                temp = np.rot90((np.concatenate((merge_img_seg_v2(xy_old[int(i)], this.yz_new[int(i)])))))
                xy_merge_list.append(temp)

                
                
        return xy_merge_list

    def run(self, file_obj):
        
        if minlay.select_flag == False:
            minlay.read_nii(file_obj)
        else:
            return minlay.run_select()
        print("run running ==========>>>>>>>")
        minlay.new_data = backstage.fn(np.array(minlay.old_data))
        print("minlay.old_data.shape = {}".format(minlay.old_data.shape))
        print("minlay.new_data.shape = {}".format(minlay.new_data.shape))
        print("run running ==========>>>>>>>")
        backstage.success()
        return backstage.success()
    
    def run_select(self):
        print("run_select running~~~~~~~")
        minlay.new_data = backstage.fn(np.array(minlay.old_data))
        backstage.success()
        return backstage.success()
    """
    def volume(this):
        left_x_lower_limit = 0
        left_x_upper_limit = 1
        left_y_lower_limit = 0
        left_y_upper_limit = 1
        left_z_lower_limit = 0
        left_z_upper_limit = 1
        
        right_x_lower_limit = 0
        right_x_upper_limit = 1
        right_y_lower_limit = 0
        right_y_upper_limit = 1
        right_z_lower_limit = 0
        right_z_upper_limit = 1
        
        x, y, z = this.new_data.shape
        
        center_line_x = x // 2
        center_line_y = y // 2
        
        left_data_x, right_data_x = np.split(this.new_data, 2, axis=0)
        
        for i in range(0, center_line_x):
            if np.allclose(left_data_x[:, :, i], np.zeros_like(left_data_x[:, :, i])) != True:
                left_z_lower_limit = i
                for e in range(i, center_line_x):
                    if np.allclose(left_data_x[:, :, e], np.zeros_like(left_data_x[:, :, e])) == True:
                        left_z_upper_limit = e
                        
        for i in range(0, center_line_x):
            if np.allclose(right_data_x[:, :, i], np.zeros_like(right_data_x[:, :, i])) != True:
                right_z_lower_limit = i
                for e in range(i, center_line_x):
                    if np.allclose(right_data_x[:, :, e], np.zeros_like(right_data_x[:, :, e])) == True:
                        right_z_upper_limit = e
                        
        for i in range(0, center_line_x):
            if np.allclose(left_data_x[:, i, :], np.zeros_like(left_data_x[:, i, :])) != True:
                left_y_lower_limit = i
                for e in range(i, center_line_x):
                    if np.allclose(left_data_x[:, e, :], np.zeros_like(left_data_x[:, e, :])) == True:
                        left_y_upper_limit = e
                        
        for i in range(0, center_line_x):
            if np.allclose(right_data_x[:, i, :], np.zeros_like(right_data_x[:, i, :])) != True:
                right_y_lower_limit = i
                for e in range(i, center_line_x):
                    if np.allclose(right_data_x[:, e, :], np.zeros_like(right_data_x[:, e, :])) == True:
                        right_y_upper_limit = e
                        
        for i in range(0, center_line_x):
            pass
                        
        for i in range(0, center_line_x):
            pass
    """
    
    def volume(this):
        
        flag = 0
        left, right = 0, 0
        xy_old = this.get_yz()
        this.yz_new = this.get_yz_test()
        for i in range(0, len(this.yz_new)):
            print(left, right)
#             print(flag, np.sum(this.yz_new[int(i)]))
            if (flag == 0 or flag == 1):
                flag = 1
                if not math.isnan(np.sum(this.yz_new[int(i)])):
                    left += np.sum(this.yz_new[int(i)])
                    
            if math.isnan(np.sum(this.yz_new[int(i)])) and flag == 1 and left > 500:
                flag = 2
            if not math.isnan(np.sum(this.yz_new[int(i)])) and (flag == 2 or flag == 3) :
                flag = 3
                right += np.sum(this.yz_new[int(i)])
        return "Left volume size: {}, Right volume size: {}".format(left, right)
                        
print("global==============>>>>>>>>>>>>>>>")
backstage = Backstage()
minlay = MiddleLayer()
print("<<<<<<<<<<<<<<<<<<<<global==============")


def threshold_segmentation(array):
    print("input type:{}".format(type(array)))
    temp = copy.deepcopy(array)
    parameter = None
    with open('./parameter.json', 'r') as json_file:
        parameter = json.load(json_file) 
    threshold_value = parameter["parameter1"]
    temp[temp < threshold_value] = 0
    return temp


############################################################################
                                                                           # 
                                                                           # 
                                                                           # 
"""                                                                        # 
@input:  numpy nd.array                                                    # 
@output: numpy nd.array                                                    #     
                                                                           # 
PS: 1.The algorithm needs to give the displayed parameters                 #
        (1) Create a file named label.json                                 # 
        (2) Write the parameters that need to be displayed                 # 
"""                                                                        # 
                                                                           # 
                                                                           # 
# backstage.fn = threshold_segmentation                                    #
backstage.fn = inference_zcyy.main_array                                   #
                                                                           # 
                                                                           # 
                                                                           # 
                                                                           # 
                                                                           # 
                                                                           # 
                                                                           # 
                                                                           # 
############################################################################

# def requset(request: gr.Request):
#     if request:
#         print("Request headers dictionary:", request.headers)
#         print("IP address:", request.client.host)
#         print("Query parameters:", dict(request.query_params))
    

def main():
    config = None
    with open('./config.json', 'r') as json_file:
        config = json.load(json_file)

    title_web_page  = str(config["title_web_page"])
    title_theme     = str(config["title_theme"])

    file_obj = None
    with gr.Blocks(title=title_web_page, equal_height = True) as app:
            gr.Label(value=title_theme, label=None, show_label=None, visible=True, container=False)

            # parameter_map = {}

            with gr.Row(equal_height = False):
                with gr.Column():
                    # login = gr.inputs.Textbox()
                    login = gr.Textbox(label= "Enter unit name")
                def login_func(str_info):
                    data = {str(str_info): str(minlay.get_time())}

                    # 读取现有的数据
                    try:
                        with open(minlay.json_file_path, 'r') as f:
                            existing_data = json.load(f)
                    except FileNotFoundError:
                        existing_data = {}

                    # 添加新的数据
                    existing_data.update(data)

                    # 将数据写回文件
                    with open(minlay.json_file_path, 'w') as f:
                        json.dump(existing_data, f, indent=4)
                    # login.submit(login_func, inputs=[login])
                with gr.Column():
                    file_obj = gr.File(label="Upload nii file", height=90)
                with gr.Column():
                    nii_selection = gr.Dropdown(["demo_001.nii", "demo_003.nii", "demo_004.nii", "demo_005.nii"], show_label = False, height = 80, info="Select demo file")
                    def nii_selection_function(obj):
                        minlay.select_flag = True
                        if obj == "demo_001.nii":
                            minlay.read_nii_select("/root/autodl-tmp/v1.1/gradio_app/input/109_1.nii.gz")
                        elif obj == "demo_003.nii":

                            minlay.read_nii_select("/root/autodl-tmp/v1.1/gradio_app/input/demo_003.nii")
                        elif obj == "demo_004.nii":

                            minlay.read_nii_select("/root/autodl-tmp/v1.1/gradio_app/input/demo_004.nii")
                        elif obj == "demo_005.nii":

                            minlay.read_nii_select("/root/autodl-tmp/v1.1/gradio_app/input/demo_005.nii")
                        # else:   #demo_006.nii

                        #     minlay.read_nii_select("/root/autodl-tmp/v1.1/gradio_app/input/demo_006.nii")
                    nii_selection.select(fn = nii_selection_function, inputs=[nii_selection], outputs=None)
                    
            with gr.Row():
                with gr.Row():
                    with gr.Column(min_width = 0):
                        btn_run = gr.Button("Run").style(full_width=True, css="button { background-color: yellow;}")
                        btn_download = gr.Button("Download").style(full_width=True)
                        
                with gr.Column(min_width = 995):
                        with gr.Row():
                            info_box = gr.Textbox(label= "Information")
                            info_box_volume = gr.Textbox(label= "Volume")

                btn_run.click(minlay.run, inputs=[file_obj], outputs=[info_box])
                
                
                btn_run.click(login_func, inputs=[login], outputs=None)

            with gr.Row():
                btn_xy = gr.Button("Transverse plane").style(full_width=True)
                btn_xz = gr.Button("Coronal plane").style(full_width=True)
                btn_yz = gr.Button("Sagittal plane").style(full_width=True)
                
            with gr.Row():
                gallery = gr.Gallery(
                    label="Show", show_label=True, elem_id="gallery_xy_out"
                ).style(columns=[1], rows=[1], object_fit="contain", height="auto", width="400px")                  
                btn_xy.click(minlay.merge_xy, inputs=[], outputs=[gallery])
                btn_xy.click(minlay.volume, inputs=[], outputs=[info_box_volume])
                btn_xz.click(minlay.merge_xz, inputs=[], outputs=[gallery])
                btn_yz.click(minlay.merge_yz, inputs=[], outputs=[gallery])
            outfile = gr.File(label="Download",container=False)
            
            btn_download.click(backstage.save, inputs=[], outputs=[outfile])
            btn_download.click(backstage.save, inputs=[], outputs=[info_box])


    # app.queue()
    # app.launch(share=True)
    
    app.queue().launch(server_name = "0.0.0.0", server_port = 6006, share=False, inbrowser=True)


if __name__ == "__main__":
    main()
    
