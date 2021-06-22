
from PIL import Image
import PySimpleGUI as sg
import io

class InferenceGUI:
    def __init__(self):
        # Left column will show the inference result
        self.left_col = [[sg.Text('Inference Results', key='-INFERENCE-')],
                    [sg.Text('No inference Performed yet',size=(40,15), key='-RESULT-')]]
        # HRight column will show the inference image
        self.images_col = [[sg.Text('Inference Image:')],
                    [sg.Text(size=(40,1), key='-IMAGE_NAME-')],
                    [sg.Image(key='-IMAGE-')]]
        # Combile to layout
        self.layout = [[sg.Column(self.left_col, element_justification='c'), sg.VSeperator(),sg.Column(self.images_col, element_justification='c')]]
        # Window creation
        self.window = sg.Window('Multiple Format Image Viewer', self.layout,resizable=True, finalize=True)

    def convert_to_bytes(self, file_or_bytes, resize=None):
        '''
        Will convert into bytes and optionally resize an image that is a file or a base64 bytes object.
        Turns into  PNG format in the process so that can be displayed by tkinter
        :param file_or_bytes: either a string filename or a bytes base64 image object
        :type file_or_bytes:  (Union[str, bytes])
        :param resize:  optional new size
        :type resize: (Tuple[int, int] or None)
        :return: (bytes) a byte-string object
        :rtype: (bytes)
        '''
        if isinstance(file_or_bytes, str):
            img = Image.open(file_or_bytes)
        else:
            img = file_or_bytes
        cur_width, cur_height = img.size
        if resize:
            new_width, new_height = resize
            scale = min(new_height/cur_height, new_width/cur_width)
            img = img.resize((int(cur_width*scale), int(cur_height*scale)), Image.ANTIALIAS)
        bio = io.BytesIO()
        img.save(bio, format="PNG")
        del img
        return bio.getvalue()

    # Update the GUI with image or inference text
    def update_window(self, field, file_or_bytes) -> bool:
        event, values = self.window.read(timeout=1)
        if event in (sg.WIN_CLOSED, 'Exit'):
            return False
        if event == sg.WIN_CLOSED or event == 'Exit':
            return False
        if field == "image":
            try:
                new_size = (256,256)
                self.window['-IMAGE-'].update(data=self.convert_to_bytes(file_or_bytes, resize=new_size))
                self.window.finalize()
            except Exception as E:
                print(f'** Error {E} **')
                return False    # something weird happened making the full filename
        elif field == "image_name":
            try:
                self.window['-IMAGE_NAME-'].update(file_or_bytes)
                self.window.finalize()
            except Exception as E:
                print(f'** Error {E} **')
                return False    # something weird happened making the full filename
        elif field == "result":
            try:
                self.window['-RESULT-'].update(file_or_bytes)
                self.window.finalize()
            except Exception as E:
                print(f'** Error {E} **')
                return False    # something weird happened making the full filename
        return True
