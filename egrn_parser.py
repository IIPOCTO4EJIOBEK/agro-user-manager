#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Скрипт для пакетного парсинга выписок ЕГРН (PDF) и формирования Excel-отчета.
Извлекает: Кадастровый номер, ОКТМО, Категория земель, Кадастровая стоимость, 
Доля, Дата выдачи выписки.

Автор: АО Агрохолдинг «Просторы»
Версия: 1.0.0
"""

import pdfplumber
import pandas as pd
import re
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Optional, Any
import logging

# Настройка логирования
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('egrn_parser.log', encoding='utf-8'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# Конфигурация
DEFAULT_PDF_FOLDER = r"C:\Выписки_ЕГРН"
DEFAULT_OUTPUT_EXCEL = "egrn_parsed_data.xlsx"
DEFAULT_OUTPUT_ERRORS = "egrn_parse_errors.xlsx"

# Коды категорий земель для сельхозназначения (для проверки ставки 0.3%)
AGRI_CATEGORY_CODES = [
    "003001000000",  # Земли сельскохозяйственного назначения
    "003001001000",  # Сельскохозяйственные угодья
    "003001002000",  # Земли, занятые объектами сельскохозяйственного назначения
    "003001003000",  # Пашни, сенокосы, пастбища, залежи
]


class EGRNParser:
    """Класс для парсинга выписок ЕГРН из PDF файлов."""
    
    def __init__(self, pdf_folder: str, output_excel: str, output_errors: str):
        self.pdf_folder = Path(pdf_folder)
        self.output_excel = output_excel
        self.output_errors = output_errors
        self.errors: List[Dict[str, Any]] = []
        
    def extract_text_from_pdf(self, pdf_path: Path) -> Optional[str]:
        """Извлекает весь текст из PDF файла."""
        try:
            with pdfplumber.open(pdf_path) as pdf:
                full_text = "".join(page.extract_text() or "" for page in pdf.pages)
            return full_text if full_text.strip() else None
        except Exception as e:
            logger.error(f"Ошибка чтения файла {pdf_path}: {e}")
            self.errors.append({
                "Файл": str(pdf_path),
                "Ошибка": f"Не удалось прочитать PDF: {str(e)}",
                "Дата_время": datetime.now().strftime("%d.%m.%Y %H:%M:%S")
            })
            return None
    
    def extract_field(self, text: str, patterns: List[str], group_idx: int = 1) -> Optional[str]:
        """
        Извлекает значение поля по одному из шаблонов.
        
        Args:
            text: Текст для поиска
            patterns: Список regex-шаблонов для поиска
            group_idx: Индекс группы захвата в regex
            
        Returns:
            Найденное значение или None
        """
        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE | re.MULTILINE)
            if match:
                value = match.group(group_idx).strip()
                return value if value else None
        return None
    
    def extract_cadastral_number(self, text: str) -> Optional[str]:
        """Извлекает кадастровый номер (формат XX:XX:XXXXXXX:X)."""
        patterns = [
            r'Кадастровый\s+номер[:\s]+([\d:]+)',
            r'Номер\s+участка[:\s]+([\d:]+)',
            r'([\d]{1,2}:[\d]{1,2}:[\d]{6,7}:[\d]{1,2})',
        ]
        return self.extract_field(text, patterns)
    
    def extract_oktmo(self, text: str) -> Optional[str]:
        """Извлекает код ОКТМО (8 цифр, возможно с пробелами)."""
        patterns = [
            r'ОКТМО[:\s]+([\d\s]{8})',
            r'Код\s+по\s+ОКТМО[:\s]+([\d\s]{8})',
            r'Муниципальное\s+образование.*?код[:\s]+([\d\s]{8})',
        ]
        value = self.extract_field(text, patterns)
        if value:
            return value.replace(" ", "")
        return None
    
    def extract_land_category(self, text: str) -> Optional[str]:
        """Извлекает категорию земель."""
        patterns = [
            r'Категория\s+земель[:\s]+(.+?)(?:\n|$|Назначение)',
            r'Категория[:\s]+(.+?)(?:\n|$)',
            r'Земли\s+(.+?)\s+назначения',
        ]
        return self.extract_field(text, patterns)
    
    def extract_cadastral_cost(self, text: str) -> Optional[float]:
        """Извлекает кадастровую стоимость в рублях."""
        patterns = [
            r'Кадастровая\s+стоимость[:\s]+([\d\s\.]+)\s*руб',
            r'Стоимость\s+\(оценка\)[:\s]+([\d\s\.]+)',
            r'Цена[:\s]+([\d\s\.]+)\s*руб',
        ]
        value = self.extract_field(text, patterns)
        if value:
            try:
                cleaned = value.replace(" ", "").replace(",", ".")
                return float(cleaned)
            except ValueError:
                logger.warning(f"Не удалось преобразовать стоимость: {value}")
        return None
    
    def extract_land_category_code(self, text: str) -> Optional[str]:
        """Извлекает код категории земель (если есть в тексте)."""
        patterns = [
            r'Код\s+категории[:\s]+(\d{12})',
            r'Категория\s+земель.*?код[:\s]+(\d{12})',
            r'Код[:\s]+(\d{12}).*?категории',
        ]
        return self.extract_field(text, patterns)
    
    def extract_share(self, text: str) -> Optional[str]:
        """Извлекает долю в праве собственности."""
        patterns = [
            r'Доля\s+вправе[:\s]+(\d+/\d+)',
            r'Доля[:\s]+(\d+/\d+)',
            r'Право\s+собственности[:\s]+.*?(\d+/\d+)',
            r'(\d+/\d+)\s+доля',
            r'Доля в праве[:\s]+(\d+/\d+)',
        ]
        return self.extract_field(text, patterns)
    
    def extract_date(self, text: str) -> Optional[str]:
        """Извлекает дату выписки или дату регистрации права."""
        patterns = [
            r'Дата\s+выписки[:\s]+(\d{2}\.\d{2}\.\d{4})',
            r'Дата\s+регистрации[:\s]+(\d{2}\.\d{2}\.\d{4})',
            r'Выписка\s+от[:\s]+(\d{2}\.\d{2}\.\d{4})',
            r'(\d{2}\.\d{2}\.\d{4})\s+г\.',
        ]
        return self.extract_field(text, patterns)
    
    def parse_single_pdf(self, pdf_path: Path) -> List[Dict[str, Any]]:
        """
        Парсит один PDF файл и возвращает список записей об участках.
        
        Args:
            pdf_path: Путь к PDF файлу
            
        Returns:
            Список словарей с данными об участках
        """
        logger.info(f"Обработка файла: {pdf_path.name}")
        
        full_text = self.extract_text_from_pdf(pdf_path)
        if not full_text:
            return []
        
        extracted_data = []
        
        # Разделяем текст по участкам (если в одном файле несколько участков)
        sections = re.split(r'(?:Сведения\s+о\s+земельном\s+участке|Раздел\s+I)', full_text, flags=re.IGNORECASE)
        
        # Если разделений не найдено, обрабатываем весь текст как один участок
        if len(sections) <= 1:
            sections = [full_text]
        
        for idx, section in enumerate(sections[1:], start=1):  # Пропускаем первый элемент (заголовок)
            data = {
                'Файл_источник': pdf_path.name,
                '№_участка_в_файле': idx,
                'Кадастровый_номер': self.extract_cadastral_number(section),
                'ОКТМО': self.extract_oktmo(section),
                'Категория_земель': self.extract_land_category(section),
                'Код_категории_земель': self.extract_land_category_code(section),
                'Кадастровая_стоимость': self.extract_cadastral_cost(section),
                'Доля': self.extract_share(section),
                'Дата': self.extract_date(section),
            }
            
            # Добавляем только если найден кадастровый номер (ключевое поле)
            if data['Кадастровый_номер']:
                extracted_data.append(data)
                logger.info(f"  ✓ Участок {data['Кадастровый_номер']} извлечен")
            else:
                logger.warning(f"  ⚠ Не найден кадастровый номер в секции {idx} файла {pdf_path.name}")
                self.errors.append({
                    "Файл": pdf_path.name,
                    "Секция": idx,
                    "Ошибка": "Не найден кадастровый номер",
                    "Дата_время": datetime.now().strftime("%d.%m.%Y %H:%M:%S")
                })
        
        if not extracted_data:
            logger.warning(f"  ✗ В файле {pdf_path.name} не найдено ни одного участка")
            self.errors.append({
                "Файл": pdf_path.name,
                "Секция": "-",
                "Ошибка": "Не найдено ни одного участка с кадастровым номером",
                "Дата_время": datetime.now().strftime("%d.%m.%Y %H:%M:%S")
            })
        
        return extracted_data
    
    def process_all_pdfs(self) -> pd.DataFrame:
        """
        Обрабатывает все PDF файлы в папке.
        
        Returns:
            DataFrame с результатами парсинга
        """
        if not self.pdf_folder.exists():
            raise FileNotFoundError(f"Папка с выписками не найдена: {self.pdf_folder}")
        
        pdf_files = list(self.pdf_folder.glob("*.pdf")) + list(self.pdf_folder.glob("*.PDF"))
        
        if not pdf_files:
            raise ValueError(f"В папке {self.pdf_folder} не найдено PDF файлов")
        
        logger.info(f"Найдено {len(pdf_files)} PDF файлов для обработки")
        
        all_records = []
        for pdf_file in pdf_files:
            records = self.parse_single_pdf(pdf_file)
            all_records.extend(records)
        
        logger.info(f"Всего извлечено {len(all_records)} записей об участках")
        
        return pd.DataFrame(all_records)
    
    def save_results(self, df: pd.DataFrame) -> None:
        """Сохраняет результаты в Excel файлы."""
        if df.empty:
            logger.warning("Нет данных для сохранения")
            return
        
        # Сохраняем основной отчет
        df.to_excel(self.output_excel, index=False, engine='openpyxl')
        logger.info(f"Основной отчет сохранен: {self.output_excel}")
        
        # Сохраняем ошибки (если есть)
        if self.errors:
            errors_df = pd.DataFrame(self.errors)
            errors_df.to_excel(self.output_errors, index=False, engine='openpyxl')
            logger.info(f"Отчет об ошибках сохранен: {self.output_errors}")
        else:
            logger.info("Ошибок при парсинге не обнаружено")
    
    def run(self) -> bool:
        """
        Запускает полный процесс парсинга.
        
        Returns:
            True если успешно, False если есть критические ошибки
        """
        try:
            logger.info("=" * 60)
            logger.info("Запуск парсера выписок ЕГРН")
            logger.info(f"Папка с выписками: {self.pdf_folder}")
            logger.info(f"Выходной файл: {self.output_excel}")
            logger.info("=" * 60)
            
            df = self.process_all_pdfs()
            self.save_results(df)
            
            logger.info("=" * 60)
            logger.info("Парсинг завершен успешно!")
            logger.info(f"Всего участков: {len(df)}")
            logger.info(f"Ошибок: {len(self.errors)}")
            logger.info("=" * 60)
            
            return len(self.errors) == 0
            
        except Exception as e:
            logger.error(f"Критическая ошибка при выполнении: {e}")
            return False


def main():
    """Точка входа в программу."""
    # Проверка аргументов командной строки
    if len(sys.argv) > 1:
        pdf_folder = sys.argv[1]
    else:
        pdf_folder = DEFAULT_PDF_FOLDER
    
    if len(sys.argv) > 2:
        output_excel = sys.argv[2]
    else:
        output_excel = DEFAULT_OUTPUT_EXCEL
    
    if len(sys.argv) > 3:
        output_errors = sys.argv[3]
    else:
        output_errors = DEFAULT_OUTPUT_ERRORS
    
    # Создание парсера и запуск
    parser = EGRNParser(pdf_folder, output_excel, output_errors)
    success = parser.run()
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
