import gradio as gr
import json
import os
import matplotlib.pyplot as plt
import numpy as np
from datetime import datetime
import mysql.connector
import shutil
from collections import defaultdict
import string
import random
from PIL import Image
import io

class Backstage:

    def generate_random_string(self, length=10):
        # 生成一个指定长度的随机字符串
        letters_and_digits = string.ascii_letters + string.digits
        random_string = ''.join(random.choice(letters_and_digits) for _ in range(length))
        return random_string


    def connect_mysql(self):
        try:
            self.conn = mysql.connector.connect(
                host="localhost",
                user="debian-sys-maint",
                password="Ju9EzOnY4XooBFRO",
                database="zcyy"
            )
            print("connect success 链接成功成功成功成功")
        except mysql.connector.Error as e:
            print(f"connect error -1 {e} 链接失败失败失败失败")

    def __init__(self) -> None:
        self.data_index = 0

        self.connect_mysql()
    
    def read_data(self):

        try:
            if self.conn is None or not self.conn.is_connected():
                self.connect_mysql()

            cursor = self.conn.cursor()
            sql = """SELECT `index`, `time`, `scale` FROM scale_tbl;"""
            cursor.execute(sql)
            rows = cursor.fetchall()
            cursor.close()
            self.conn.close()
            print("res row = ", rows.__len__())
            for row in rows:
                print(row)
        except mysql.connector.Error as e:
            print(f"select error: {e}")

        plt.clf()

        data = rows

        if data is not None:
            indexs = [row[0] for row in data]
            scales = [float(row[2]) for row in data]
        else:
            print("data is none")
            return None

        plt.plot(indexs, scales)
        plt.xlabel('Index')
        plt.ylabel('Scale')
        plt.title('Scale vs Index')

        plt.xticks(np.arange(0, data.__len__(), 1))

        plt.yticks(np.arange(0, 361, 45))

        fig = plt.gcf()
        fig.canvas.draw()
        image_matrix = np.array(fig.canvas.renderer.buffer_rgba())

        print("shape = ", image_matrix.shape)

        return image_matrix, rows
        

    def write_data(self, img, scale):

        # 源文件路径
        source_file = img.name
        file_name, file_extension = os.path.splitext(source_file)

        # 目标文件路径（包括新的文件名和路径）
        destination_file = "../data/image/" + self.generate_random_string() + file_extension

        # 使用 shutil.copy() 函数复制文件并重命名副本
        shutil.copy(source_file, destination_file)

        try:
            if self.conn is None or not self.conn.is_connected():
                self.connect_mysql()

            cursor = self.conn.cursor()

            insert_query = """
            INSERT INTO scale_tbl (`time`, `scale`, `path`) 
            VALUES (%s, %s, %s)
            """ 
            current_time = datetime.now()
            cursor.execute(insert_query, (str(current_time), float(scale), destination_file))
            self.conn.commit()

            if cursor.rowcount > 0:
                print("insert success！")
                return True
            else:
                print("insert failed: no affected rows")
                return False
        except mysql.connector.Error as e:
            print(f"insert failed: {e}")
            return False
    
    def check_image(self, index):
        print("check_image_index = ", index)
        try:
            if self.conn is None or not self.conn.is_connected():
                self.connect_mysql()

            cursor = self.conn.cursor()
            sql = """SELECT `path` FROM scale_tbl WHERE `index` = %s;"""
            cursor.execute(sql, (index,))
            relative_image_path = cursor.fetchall()[0][0]
            cursor.close()
            self.conn.close()

            # 构建绝对路径
            absolute_image_path = os.path.join(".", relative_image_path)
            print("res = ", absolute_image_path)

            # 打开图像文件
            return Image.open(absolute_image_path)
        except mysql.connector.Error as e:
            print(f"select error: {e}")
            return None

    
def main():
    
    backstage = Backstage()

    file_obj = None

    with gr.Blocks() as app:

        gr.Label(value="测试代码", label=None, show_label=None, visible=True, container=False)

        with gr.Row(variant="default"):
            # with gr.Column():
            image_file = gr.File(height=155, min_width = 745, label="input image")
            scale_value = gr.Textbox(placeholder="...", label="input scale", container=False).style(height=30)

            with gr.Column():
                set_button = gr.Button("Set")
                refresh_button = gr.Button("Refresh")
                check_button = gr.Button("Check")

        with gr.Row():
            table = gr.Dataframe(
                headers=['index', 'time', 'scale'],
                datatype=["str", "str", "str"],
                row_count=5,
                col_count=(3, "fixed"),
            )
            
            show_image = gr.Image()
            set_button.click(fn=backstage.write_data, inputs=[image_file, scale_value], outputs=[])
            refresh_button.click(fn=backstage.read_data, inputs=[], outputs=[show_image, table])
            check_button.click(fn=backstage.check_image, inputs=[scale_value], outputs=[show_image])

        app.queue().launch(server_name = "0.0.0.0", server_port = 6006, share=True, inbrowser=True)

if __name__ == "__main__":
    main()